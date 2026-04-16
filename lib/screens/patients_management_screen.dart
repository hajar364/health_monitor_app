import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/patient_profile.dart';

class PatientsManagementScreen extends StatefulWidget {
  const PatientsManagementScreen({Key? key}) : super(key: key);

  @override
  State<PatientsManagementScreen> createState() => _PatientsManagementScreenState();
}

class _PatientsManagementScreenState extends State<PatientsManagementScreen> {
  List<PatientProfile> patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  void _loadPatients() {
    // Données de test
    setState(() {
      patients = [
        PatientProfile(
          id: const Uuid().v4(),
          name: 'Jean Dupont',
          age: 78,
          height: 172,
          weight: 75,
          emergencyContact: 'Marie Dupont',
          emergencyPhone: '+33612345678',
          medicalConditions: ['Hypertension', 'Diabète'],
          registeredDate: DateTime.now(),
          isActive: true,
        ),
        PatientProfile(
          id: const Uuid().v4(),
          name: 'Marie Martin',
          age: 82,
          height: 165,
          weight: 68,
          emergencyContact: 'Pierre Martin',
          emergencyPhone: '+33687654321',
          medicalConditions: ['Ostéoporose'],
          registeredDate: DateTime.now(),
          isActive: true,
        ),
      ];
    });
  }

  void _showPatientDialog({PatientProfile? patient}) {
    final isEdit = patient != null;
    final nameCtrl = TextEditingController(text: patient?.name ?? '');
    final ageCtrl = TextEditingController(text: patient?.age.toString() ?? '');
    final contactCtrl = TextEditingController(text: patient?.emergencyContact ?? '');
    final phoneCtrl = TextEditingController(text: patient?.emergencyPhone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Modifier Patient' : 'Ajouter Patient'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: ageCtrl,
                decoration: const InputDecoration(labelText: 'Âge'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: contactCtrl,
                decoration: const InputDecoration(labelText: 'Contact d\'urgence'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final newPatient = PatientProfile(
                id: patient?.id ?? const Uuid().v4(),
                name: nameCtrl.text,
                age: int.tryParse(ageCtrl.text) ?? 0,
                height: patient?.height ?? 170,
                weight: patient?.weight ?? 70,
                emergencyContact: contactCtrl.text,
                emergencyPhone: phoneCtrl.text,
                registeredDate: patient?.registeredDate ?? DateTime.now(),
              );

              setState(() {
                if (isEdit) {
                  final idx = patients.indexWhere((p) => p.id == patient.id);
                  if (idx >= 0) patients[idx] = newPatient;
                } else {
                  patients.add(newPatient);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 Gestion des Patients'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: patients.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add,
                    size: 64,
                    color: Colors.blue.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text('Aucun patient enregistré'),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _showPatientDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un patient'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade600,
                      child: Text(
                        patient.name[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(patient.getDisplayName()),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📞 ${patient.emergencyContact}'),
                        Text(
                          patient.medicalConditions.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          child: Text('Éditer'),
                          value: 'edit',
                        ),
                        const PopupMenuItem(
                          child: Text('Supprimer'),
                          value: 'delete',
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showPatientDialog(patient: patient);
                        } else if (value == 'delete') {
                          setState(() {
                            patients.removeAt(index);
                          });
                        }
                      },
                    ),
                    onTap: () => _showPatientDetail(patient),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPatientDialog(),
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPatientDetail(PatientProfile patient) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.shade600,
                child: Text(
                  patient.name[0],
                  style: const TextStyle(color: Colors.white, fontSize: 32),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                patient.getDisplayName(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('📏 Taille', '${patient.height.toInt()} cm'),
            _buildDetailRow('⚖️ Poids', '${patient.weight.toInt()} kg'),
            _buildDetailRow('📞 Contact', patient.emergencyContact),
            _buildDetailRow('☎️ Téléphone', patient.emergencyPhone),
            if (patient.medicalConditions.isNotEmpty)
              _buildDetailRow('⚕️ Conditions', patient.medicalConditions.join(', ')),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showPatientDialog(patient: patient);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Éditer'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Fermer'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
