import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../datos/globales.dart';
import '../servicios/servicio_imagen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final bioCtrl = TextEditingController();

  File? _imageFile;
  String? _existingImageBase64;
  final ImagePicker _picker = ImagePicker();

  // Nuevos campos para ML Profile
  final skillInputCtrl = TextEditingController();
  List<String> _skills = [];
  String _experience = 'Junior'; // Valor por defecto
  final List<String> _experienceLevels = ['Junior', 'Mid', 'Senior', 'Lead'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (loggedUser != null) {
      nameCtrl.text = loggedUser!.name;
      phoneCtrl.text = loggedUser!.phone;
      nameCtrl.text = loggedUser!.name;
      phoneCtrl.text = loggedUser!.phone;
      bioCtrl.text = loggedUser!.bio;

      // Cargar skills y experiencia existentes
      _skills = List.from(loggedUser!.skills);
      if (loggedUser!.experience.isNotEmpty) {
        _experience = loggedUser!.experience;
      }

      // Normalizar experiencia si no coincide con los niveles definidos
      if (!_experienceLevels.contains(_experience)) {
        _experience = 'Mid';
      }

      if (loggedUser!.profileImagePath.isNotEmpty) {
        if (ImageService.isBase64(loggedUser!.profileImagePath)) {
          _existingImageBase64 = loggedUser!.profileImagePath;
        }
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _existingImageBase64 = null;
        });
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar imagen: $e', isError: true);
    }
  }

  Future<void> _saveProfile() async {
    if (nameCtrl.text.isEmpty) {
      _showSnackBar('El nombre no puede estar vacío', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageBase64 = _existingImageBase64 ?? '';

      if (_imageFile != null) {
        imageBase64 = ImageService.imageToBase64(_imageFile!);
      }

      loggedUser!.name = nameCtrl.text;
      loggedUser!.phone = phoneCtrl.text;
      loggedUser!.bio = bioCtrl.text;
      loggedUser!.profileImagePath = imageBase64;
      loggedUser!.skills = _skills;
      loggedUser!.experience = _experience;

      await FirebaseFirestore.instance
          .collection('wanka_users')
          .doc(loggedUser!.email)
          .update({
            'name': nameCtrl.text,
            'phone': phoneCtrl.text,
            'bio': bioCtrl.text,
            'profileImagePath': imageBase64,
            'skills': _skills,
            'experience': _experience,
          });

      if (mounted) {
        _showSnackBar('Perfil actualizado exitosamente', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Error al guardar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade700, Colors.grey.shade50],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Editar Perfil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Profile Picture
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: ClipOval(child: _buildProfileImage()),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade700,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Toca para cambiar foto',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 32),

                        // Name
                        _buildTextField(
                          controller: nameCtrl,
                          label: 'Nombre completo',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        _buildTextField(
                          controller: phoneCtrl,
                          label: 'Teléfono',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        // Bio
                        _buildTextField(
                          controller: bioCtrl,
                          label: 'Biografía',
                          icon: Icons.info_outline,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),

                        // Skills Section - CRUCIAL PARA ML
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Habilidades (Para recomendaciones IA)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: skillInputCtrl,
                                label: 'Agregar habilidad (ej: Flutter)',
                                icon: Icons.code,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _addSkill,
                              icon: const Icon(Icons.add_circle),
                              color: Colors.purple,
                              iconSize: 40,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildSkillsChips(),
                        const SizedBox(height: 24),

                        // Experience Level Section
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Nivel de Experiencia',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _experience,
                              isExpanded: true,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.purple.shade700,
                              ),
                              items:
                                  _experienceLevels.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _experience = newValue!;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save_outlined),
                                        SizedBox(width: 12),
                                        Text(
                                          'GUARDAR CAMBIOS',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    } else if (_existingImageBase64 != null) {
      return Image.memory(
        ImageService.base64ToImage(_existingImageBase64!),
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.purple.shade600],
          ),
        ),
        child: const Icon(Icons.person, size: 70, color: Colors.white),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.purple.shade700),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.purple.shade700, width: 2),
        ),
      ),
    );
  }

  void _addSkill() {
    final skill = skillInputCtrl.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        skillInputCtrl.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  Widget _buildSkillsChips() {
    if (_skills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Agrega habilidades para recibir recomendaciones de empleo personalizadas.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _skills.map((skill) {
            return Chip(
              label: Text(skill),
              labelStyle: const TextStyle(color: Colors.white),
              backgroundColor: Colors.purple.shade400,
              deleteIcon: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
              onDeleted: () => _removeSkill(skill),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          }).toList(),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    bioCtrl.dispose();
    skillInputCtrl.dispose();
    super.dispose();
  }
}
