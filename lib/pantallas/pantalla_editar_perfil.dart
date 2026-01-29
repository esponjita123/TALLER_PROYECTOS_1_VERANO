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

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final skillInputCtrl = TextEditingController();

  File? _imageFile;
  String? _existingImageBase64;
  final ImagePicker _picker = ImagePicker();

  List<String> _skills = [];
  String _experience = 'Junior';
  final List<String> _experienceLevels = ['Junior', 'Mid', 'Senior', 'Lead'];

  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    if (loggedUser != null) {
      nameCtrl.text = loggedUser!.name;
      phoneCtrl.text = loggedUser!.phone;
      bioCtrl.text = loggedUser!.bio;
      _skills = List.from(loggedUser!.skills);
      _experience =
          loggedUser!.experience.isNotEmpty ? loggedUser!.experience : 'Junior';

      if (!_experienceLevels.contains(_experience)) {
        _experience = 'Mid';
      }

      if (loggedUser!.profileImagePath.isNotEmpty &&
          ImageService.isBase64(loggedUser!.profileImagePath)) {
        _existingImageBase64 = loggedUser!.profileImagePath;
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
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient Deco
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.purple.withOpacity(0.1), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          _buildProfileImageSection(),
                          const SizedBox(height: 32),
                          _buildSectionTitle('Información Personal'),
                          const SizedBox(height: 16),
                          _buildPremiumTextField(
                            controller: nameCtrl,
                            label: 'Nombre completo',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildPremiumTextField(
                            controller: phoneCtrl,
                            label: 'Teléfono de contacto',
                            icon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          _buildPremiumTextField(
                            controller: bioCtrl,
                            label: 'Sobre mí / Biografía',
                            icon: Icons.history_edu_rounded,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle('Habilidades e IA'),
                          const SizedBox(height: 16),
                          _buildSkillsInputSection(),
                          const SizedBox(height: 16),
                          _buildSkillsChips(),
                          const SizedBox(height: 32),
                          _buildSectionTitle('Nivel Profesional'),
                          const SizedBox(height: 16),
                          _buildExperienceSelector(),
                          const SizedBox(height: 40),
                          _buildSaveButton(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.purple.shade700,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Mi Perfil',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2E3E5C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(child: _buildProfileImage()),
          ),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
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
        color: Colors.grey.shade100,
        child: Icon(
          Icons.person_rounded,
          size: 60,
          color: Colors.purple.shade200,
        ),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.purple.shade700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.blueGrey.shade400,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: Colors.purple.shade400, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.purple.shade700,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildSkillsInputSection() {
    return Row(
      children: [
        Expanded(
          child: _buildPremiumTextField(
            controller: skillInputCtrl,
            label: 'Añadir habilidad (ej: Flutter)',
            icon: Icons.auto_awesome_rounded,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _addSkill,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade500, Colors.purple.shade800],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsChips() {
    if (_skills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Añade habilidades para que la IA te sugiera mejores empleos.',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          _skills.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    skill,
                    style: TextStyle(
                      color: Colors.purple.shade800,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _removeSkill(skill),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.purple.shade600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildExperienceSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _experience,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.purple.shade700,
          ),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          items:
              _experienceLevels.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
          onChanged: (newValue) {
            setState(() => _experience = newValue!);
          },
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.purple.shade800],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'GUARDAR PERFIL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
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
    setState(() => _skills.remove(skill));
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    bioCtrl.dispose();
    skillInputCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
