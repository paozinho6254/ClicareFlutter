import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/doctor_model.dart';
import '../../models/schedule_config_model.dart';

class ManageDoctorScreen extends StatefulWidget {
  final DoctorModel? doctor;
  const ManageDoctorScreen({super.key, this.doctor});

  @override
  State<ManageDoctorScreen> createState() => _ManageDoctorScreenState();
}

class _ManageDoctorScreenState extends State<ManageDoctorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controllers Perfil
  final _nomeCtrl = TextEditingController();
  final _espCtrl = TextEditingController();
  final _crmCtrl = TextEditingController();

  bool _isLoading = false;
  int? _createdDoctorId;

  int _duracaoPadrao = 30; // Duração padrão
  final Map<int, ScheduleConfigModel> _scheduleMap = {};
  final Map<int, bool> _activeDays = {1: false, 2: false, 3: false, 4: false, 5: false, 6: false, 7: false};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _createdDoctorId = widget.doctor?.id;

    if (widget.doctor != null) {
      _nomeCtrl.text = widget.doctor!.nome;
      _espCtrl.text = widget.doctor!.especialidade;
      _crmCtrl.text = widget.doctor!.crm;
      _fetchSchedules();
    }
  }

  Future<void> _fetchSchedules() async {
    if (_createdDoctorId == null) return;
    final response = await _supabase.from('horarios_config').select().eq('medico_id', _createdDoctorId!);
    final list = (response as List).map((e) => ScheduleConfigModel.fromJson(e)).toList();

    setState(() {
      if (list.isNotEmpty) _duracaoPadrao = list.first.duracaoMinutos; // Pega a duração salva
      for (var s in list) {
        _scheduleMap[s.diaSemana] = s;
        _activeDays[s.diaSemana] = true;
      }
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      final data = {
        'clinica_id': user!.id,
        'nome': _nomeCtrl.text,
        'especialidade': _espCtrl.text,
        'crm': _crmCtrl.text,
        'ativo': true
      };

      if (_createdDoctorId == null) {
        final res = await _supabase.from('medicos').insert(data).select().single();
        _createdDoctorId = res['id'];
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvo! Configure os horários.')));
        _tabController.animateTo(1);
      } else {
        await _supabase.from('medicos').update(data).eq('id', _createdDoctorId!);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Atualizado!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSchedules() async {
    if (_createdDoctorId == null) return;
    setState(() => _isLoading = true);
    try {
      await _supabase.from('horarios_config').delete().eq('medico_id', _createdDoctorId!);
      List<Map<String, dynamic>> toInsert = [];
      _activeDays.forEach((dia, isActive) {
        if (isActive) {
          final config = _scheduleMap[dia] ?? ScheduleConfigModel(
              diaSemana: dia,
              horaInicio: const TimeOfDay(hour: 8, minute: 0),
              horaFim: const TimeOfDay(hour: 18, minute: 0),
              duracaoMinutos: _duracaoPadrao
          );
          // Garante que envia a duração selecionada no dropdown
          toInsert.add({
            ...config.toSupabase(_createdDoctorId!),
            'duracao_consulta_minutos': _duracaoPadrao
          });
        }
      });
      if (toInsert.isNotEmpty) await _supabase.from('horarios_config').insert(toInsert);
      if(mounted) Navigator.pop(context, true);
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Médico'),
        backgroundColor: const Color(0xFF319F86),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Perfil'), Tab(text: 'Horários')]),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(controller: _nomeCtrl, decoration: const InputDecoration(labelText: 'Nome'), validator: (v)=>v!.isEmpty?'Erro':null),
                TextFormField(controller: _espCtrl, decoration: const InputDecoration(labelText: 'Especialidade'), validator: (v)=>v!.isEmpty?'Erro':null),
                TextFormField(controller: _crmCtrl, decoration: const InputDecoration(labelText: 'CRM')),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _saveProfile, child: const Text('Salvar Perfil'))
              ]),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("Duração da Consulta (Define os Blocos):", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<int>(
                value: _duracaoPadrao,
                isExpanded: true,
                items: const [15, 30, 45, 60].map((e) => DropdownMenuItem(value: e, child: Text("$e minutos"))).toList(),
                onChanged: (v) => setState(() => _duracaoPadrao = v!),
              ),
              const Divider(),
              ...List.generate(7, (index) {
                final dia = index + 1;
                final active = _activeDays[dia]!;
                final conf = _scheduleMap[dia] ?? ScheduleConfigModel(diaSemana: dia, horaInicio: const TimeOfDay(hour: 8, minute: 0), horaFim: const TimeOfDay(hour: 18, minute: 0));
                return SwitchListTile(
                  title: Text(_getNomeDia(dia)),
                  subtitle: active ? Text("${conf.horaInicio.format(context)} às ${conf.horaFim.format(context)}") : null,
                  value: active,
                  onChanged: (val) {
                    setState(() {
                      _activeDays[dia] = val;
                      if(val) _scheduleMap[dia] = conf;
                    });
                  },
                );
              }),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _saveSchedules, child: const Text('Salvar Horários'))
            ],
          )
        ],
      ),
    );
  }

  String _getNomeDia(int d) => ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][d-1];
}