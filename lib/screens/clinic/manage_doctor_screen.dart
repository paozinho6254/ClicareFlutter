import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/doctor_model.dart';
import '../../models/schedule_config_model.dart';

class ManageDoctorScreen extends StatefulWidget {
  final DoctorModel? doctor; // Se null, é novo cadastro
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
  int? _createdDoctorId; // ID salvo após criar o médico

  // Controle de Horários (Memória Local)
  // Mapa: Dia da semana (1-7) -> Objeto de Configuração
  final Map<int, ScheduleConfigModel> _scheduleMap = {};
  // Mapa auxiliar para saber se o dia está ativo na UI
  final Map<int, bool> _activeDays = {1: false, 2: false, 3: false, 4: false, 5: false, 6: false, 7: false};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _createdDoctorId = widget.doctor?.id;

    if (widget.doctor != null) {
      // Modo Edição: Preenche dados
      _nomeCtrl.text = widget.doctor!.nome;
      _espCtrl.text = widget.doctor!.especialidade;
      _crmCtrl.text = widget.doctor!.crm;
      _fetchSchedules(); // Busca horários existentes
    }
  }

  // Busca horários do Supabase
  Future<void> _fetchSchedules() async {
    if (_createdDoctorId == null) return;
    final response = await _supabase
        .from('horarios_config')
        .select()
        .eq('medico_id', _createdDoctorId!);

    final list = (response as List).map((e) => ScheduleConfigModel.fromJson(e)).toList();

    setState(() {
      for (var s in list) {
        _scheduleMap[s.diaSemana] = s;
        _activeDays[s.diaSemana] = true;
      }
    });
  }

  // Salva ou Atualiza o Médico
  Future<void> _saveProfile() async {
    print("Iniciando salvamento do médico..."); // DEBUG

    if (!_formKey.currentState!.validate()) {
      print("Erro de validação do formulário"); // DEBUG
      return;
    }


    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception("Usuário não logado!");
      }

      print("ID do Usuário Logado (Clínica): ${user.id}"); // DEBUG

      // Prepara os dados
      final data = {
        'clinica_id': user.id, // Garanta que esta coluna existe no banco
        'nome': _nomeCtrl.text,
        'especialidade': _espCtrl.text,
        'crm': _crmCtrl.text,
        'ativo': true,
      };

      print("Enviando dados: $data"); // DEBUG

      if (_createdDoctorId == null) {
        // --- MODO CRIAÇÃO ---
        print("Tentando Inserir...");

        final res = await _supabase
            .from('medicos')
            .insert(data)
            .select()
            .single(); // .single() retorna erro se não inserir

        print("Sucesso na inserção! Resposta: $res"); // DEBUG

        _createdDoctorId = res['id']; // O Supabase retorna 'id' (int)

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Médico criado! Configure os horários.'), backgroundColor: Colors.green)
          );
          _tabController.animateTo(1); // Vai para aba horários
        }
      } else {
        // --- MODO ATUALIZAÇÃO ---
        print("Tentando Atualizar ID $_createdDoctorId...");

        await _supabase
            .from('medicos')
            .update(data)
            .eq('id', _createdDoctorId!); // id aqui é o BIGINT da tabela medicos

        print("Sucesso na atualização!");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dados atualizados!'), backgroundColor: Colors.green)
          );
        }
      }
    } catch (e) {
      print("ERRO AO SALVAR MÉDICO: $e"); // <--- OLHE ISSO NO CONSOLE
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salvo com sucesso!'), backgroundColor: Colors.green)
      );
      // O 'true' aqui avisa a tela anterior que houve mudança
      Navigator.pop(context, true);
    }
  }

  // Salva os Horários
  Future<void> _saveSchedules() async {
    if (_createdDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salve o perfil do médico primeiro.')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Estratégia Simples: Apaga tudo desse médico e recria os ativos
      // (Em produção, faríamos um upsert mais inteligente, mas isso funciona bem)
      await _supabase.from('horarios_config').delete().eq('medico_id', _createdDoctorId!);

      List<Map<String, dynamic>> toInsert = [];

      _activeDays.forEach((dia, isActive) {
        if (isActive) {
          // Pega o config da memória ou cria um padrão (08h as 18h)
          final config = _scheduleMap[dia] ?? ScheduleConfigModel(
            diaSemana: dia,
            horaInicio: const TimeOfDay(hour: 8, minute: 0),
            horaFim: const TimeOfDay(hour: 18, minute: 0),
          );
          toInsert.add(config.toSupabase(_createdDoctorId!));
        }
      });

      if (toInsert.isNotEmpty) {
        await _supabase.from('horarios_config').insert(toInsert);
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Horários salvos com sucesso!')));
      Navigator.pop(context); // Volta para a lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar horários: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctor == null ? 'Novo Médico' : 'Editar Médico'),
        backgroundColor: const Color(0xFF319F86),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Perfil'), Tab(text: 'Horários de Atendimento')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          // ABA 1: Perfil
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(controller: _nomeCtrl, decoration: const InputDecoration(labelText: 'Nome do Médico'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                  TextFormField(controller: _espCtrl, decoration: const InputDecoration(labelText: 'Especialidade (Ex: Cardiologista)'), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                  TextFormField(controller: _crmCtrl, decoration: const InputDecoration(labelText: 'CRM')),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _saveProfile, child: const Text('Salvar Dados'))
                ],
              ),
            ),
          ),

          // ABA 2: Horários
          ListView(
            padding: const EdgeInsets.all(10),
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Selecione os dias e horários de atendimento:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ...List.generate(7, (index) {
                final dia = index + 1; // 1 = Seg
                final nomeDia = _getNomeDia(dia);
                final isActive = _activeDays[dia]!;
                // Recupera configuração atual ou usa padrão
                final config = _scheduleMap[dia] ?? ScheduleConfigModel(diaSemana: dia, horaInicio: const TimeOfDay(hour: 8, minute: 0), horaFim: const TimeOfDay(hour: 18, minute: 0));

                return Card(
                  color: isActive ? Colors.white : Colors.grey[100],
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(nomeDia, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                        value: isActive,
                        activeColor: const Color(0xFF319F86),
                        onChanged: (val) {
                          setState(() {
                            _activeDays[dia] = val;
                            // Se ativou e não tinha config, salva a padrão no mapa
                            if (val && !_scheduleMap.containsKey(dia)) {
                              _scheduleMap[dia] = config;
                            }
                          });
                        },
                      ),
                      if (isActive)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              _timeButton("Início", config.horaInicio, (t) => _updateTime(dia, t, true)),
                              const SizedBox(width: 10),
                              const Text("até"),
                              const SizedBox(width: 10),
                              _timeButton("Fim", config.horaFim, (t) => _updateTime(dia, t, false)),
                            ],
                          ),
                        )
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF319F86), foregroundColor: Colors.white),
                  onPressed: _saveSchedules,
                  child: const Text('Confirmar Horários')
              ),
              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }

  String _getNomeDia(int dia) {
    switch(dia) {
      case 1: return 'Segunda-feira';
      case 2: return 'Terça-feira';
      case 3: return 'Quarta-feira';
      case 4: return 'Quinta-feira';
      case 5: return 'Sexta-feira';
      case 6: return 'Sábado';
      case 7: return 'Domingo';
      default: return '';
    }
  }

  Widget _timeButton(String label, TimeOfDay time, Function(TimeOfDay) onSelect) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () async {
          final newTime = await showTimePicker(context: context, initialTime: time);
          if (newTime != null) onSelect(newTime);
        },
        child: Text("$label: ${time.format(context)}"),
      ),
    );
  }

  void _updateTime(int dia, TimeOfDay newTime, bool isStart) {
    setState(() {
      final old = _scheduleMap[dia]!;
      _scheduleMap[dia] = ScheduleConfigModel(
          id: old.id,
          diaSemana: old.diaSemana,
          horaInicio: isStart ? newTime : old.horaInicio,
          horaFim: isStart ? old.horaFim : newTime,
          duracaoMinutos: old.duracaoMinutos
      );
    });
  }
}