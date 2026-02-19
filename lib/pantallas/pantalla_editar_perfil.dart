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
  String _experience = 'Básico';
  final List<String> _experienceLevels = [
    'Básico',
    'Intermedio',
    'Avanzado',
    'Experto',
  ];

  // Sugerencias de oficios casuales/profesionales
  final List<String> _suggestedSkills = [
    'Costura',
    'Carpintería',
    'Soldadura',
    'Electricidad',
    'Cocina',
    'Limpieza',
    'Pintura',
    'Albañilería',
    'Mecánica',
    'Jardinería',
    'Plomería',
    'Panadería',
    'Peluquería',
    'Conducción',
    'Cuidado niños',
    'Tejido',
    'Repostería',
    'Ganadería',
    'Agricultura',
    'Ventas',
  ];

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
          loggedUser!.experience.isNotEmpty ? loggedUser!.experience : 'Básico';

      if (!_experienceLevels.contains(_experience)) {
        _experience = 'Básico';
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFCE93D8) : Colors.purple.shade600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withOpacity(isDark ? 0.08 : 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primary.withOpacity(isDark ? 0.05 : 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, cs, isDark),
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
                          _buildProfileImageSection(theme, cs, isDark, accent),
                          const SizedBox(height: 32),

                          // ── Información Personal ──
                          _buildSectionCard(
                            theme,
                            cs,
                            isDark,
                            accent,
                            title: 'Información Personal',
                            icon: Icons.person_outline_rounded,
                            children: [
                              _buildPremiumTextField(
                                controller: nameCtrl,
                                label: 'Nombre completo',
                                icon: Icons.person_outline_rounded,
                                theme: theme,
                                cs: cs,
                                isDark: isDark,
                                accent: accent,
                              ),
                              const SizedBox(height: 14),
                              _buildPremiumTextField(
                                controller: phoneCtrl,
                                label: 'Teléfono de contacto',
                                icon: Icons.phone_android_rounded,
                                keyboardType: TextInputType.phone,
                                theme: theme,
                                cs: cs,
                                isDark: isDark,
                                accent: accent,
                              ),
                              const SizedBox(height: 14),
                              _buildPremiumTextField(
                                controller: bioCtrl,
                                label: 'Sobre mí / Experiencia laboral',
                                icon: Icons.history_edu_rounded,
                                maxLines: 3,
                                hint:
                                    'Describe tu experiencia y qué trabajos buscas...',
                                theme: theme,
                                cs: cs,
                                isDark: isDark,
                                accent: accent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Oficios y Habilidades ──
                          _buildSectionCard(
                            theme,
                            cs,
                            isDark,
                            accent,
                            title: 'Oficios y Habilidades',
                            icon: Icons.construction_rounded,
                            children: [
                              _buildSkillsInputSection(
                                theme,
                                cs,
                                isDark,
                                accent,
                              ),
                              const SizedBox(height: 14),
                              _buildSuggestedSkills(theme, cs, isDark, accent),
                              const SizedBox(height: 14),
                              _buildSkillsChips(theme, cs, isDark, accent),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Nivel de Habilidad ──
                          _buildSectionCard(
                            theme,
                            cs,
                            isDark,
                            accent,
                            title: 'Nivel de Habilidad',
                            icon: Icons.trending_up_rounded,
                            children: [
                              _buildExperienceSelector(
                                theme,
                                cs,
                                isDark,
                                accent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          _buildSaveButton(theme, cs, isDark, accent),
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

  Widget _buildHeader(BuildContext context, ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor:
                  isDark ? cs.surfaceContainerHighest : Colors.grey.shade100,
              foregroundColor: cs.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Mi Perfil',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border:
            isDark
                ? Border.all(color: cs.outlineVariant.withOpacity(0.5))
                : null,
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileImageSection(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? cs.outlineVariant : Colors.white,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(isDark ? 0.15 : 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(child: _buildProfileImage(cs, isDark, accent)),
          ),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 3,
                ),
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

  Widget _buildProfileImage(ColorScheme cs, bool isDark, Color accent) {
    if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    } else if (_existingImageBase64 != null) {
      return Image.memory(
        ImageService.base64ToImage(_existingImageBase64!),
        fit: BoxFit.cover,
      );
    } else {
      return Container(
        color: cs.surfaceContainerHighest,
        child: Icon(
          Icons.person_rounded,
          size: 60,
          color: accent.withOpacity(0.4),
        ),
      );
    }
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme cs,
    required bool isDark,
    required Color accent,
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: cs.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.3)),
          prefixIcon: Icon(icon, color: accent, size: 22),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          floatingLabelStyle: TextStyle(
            color: accent,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildSkillsInputSection(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildPremiumTextField(
            controller: skillInputCtrl,
            label: 'Añadir oficio (ej: Costurero)',
            icon: Icons.construction_rounded,
            theme: theme,
            cs: cs,
            isDark: isDark,
            accent: accent,
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: accent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _addSkill,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 52,
              width: 52,
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedSkills(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    // Filter out already-added skills
    final available =
        _suggestedSkills.where((s) => !_skills.contains(s)).toList();

    if (available.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sugerencias rápidas:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              available.take(10).map((skill) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _skills.add(skill);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(isDark ? 0.08 : 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accent.withOpacity(isDark ? 0.2 : 0.15),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          size: 14,
                          color: accent.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          skill,
                          style: TextStyle(
                            fontSize: 12,
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildSkillsChips(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    if (_skills.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isDark ? Colors.orange.withOpacity(0.1) : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.orange.shade100,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              color: isDark ? Colors.orange.shade300 : Colors.orange.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Añade tus oficios para encontrar empleos que se ajusten a tu experiencia.',
                style: TextStyle(
                  color:
                      isDark ? Colors.orange.shade300 : Colors.orange.shade700,
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
                color: accent.withOpacity(isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withOpacity(isDark ? 0.2 : 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 14, color: accent),
                  const SizedBox(width: 6),
                  Text(
                    skill,
                    style: TextStyle(
                      color: isDark ? accent : Colors.purple.shade800,
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
                      color: accent.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildExperienceSelector(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Qué tan experimentado te consideras?',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children:
              _experienceLevels.map((level) {
                final isSelected = _experience == level;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _experience = level),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? accent
                                : (isDark
                                    ? cs.surfaceContainerHighest
                                    : const Color(0xFFF0F0F5)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              isSelected
                                  ? accent
                                  : (isDark
                                      ? cs.outlineVariant
                                      : Colors.grey.shade200),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getLevelIcon(level),
                            size: 22,
                            color:
                                isSelected
                                    ? Colors.white
                                    : cs.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            level,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : cs.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'Básico':
        return Icons.emoji_events_outlined;
      case 'Intermedio':
        return Icons.trending_up;
      case 'Avanzado':
        return Icons.star_half_rounded;
      case 'Experto':
        return Icons.workspace_premium;
      default:
        return Icons.circle_outlined;
    }
  }

  Widget _buildSaveButton(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [accent.withOpacity(0.9), accent.withOpacity(0.7)]
                  : [Colors.purple.shade600, Colors.purple.shade800],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(isDark ? 0.2 : 0.3),
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
                    SizedBox(width: 12),
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
