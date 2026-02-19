import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../datos/globales.dart';
import '../modelos/modelo_empleo.dart';
import '../servicios/servicio_imagen.dart';
import 'pantalla_selector_ubicacion.dart';

class AddJobScreen extends StatefulWidget {
  final Job? jobToEdit;

  const AddJobScreen({super.key, this.jobToEdit});

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen>
    with SingleTickerProviderStateMixin {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final salaryMinCtrl = TextEditingController();
  final salaryMaxCtrl = TextEditingController();
  final requirementCtrl = TextEditingController();

  File? _imageFile;
  String? _existingImageBase64;
  final ImagePicker _picker = ImagePicker();

  List<String> _requirements = [];
  String _jobType = 'profesional';
  final List<String> _jobTypes = [
    'profesional',
    'temporal',
    'medio-tiempo',
    'por-obra',
    'remoto',
  ];

  double? _selectedLat;
  double? _selectedLng;

  bool isLoading = false;
  bool isEditing = false;

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

    if (widget.jobToEdit != null) {
      isEditing = true;
      final job = widget.jobToEdit!;
      titleCtrl.text = job.title;
      descCtrl.text = job.description;
      locationCtrl.text = job.location;
      phoneCtrl.text = job.phone;
      salaryMinCtrl.text = job.salaryMin > 0 ? job.salaryMin.toString() : '';
      salaryMaxCtrl.text = job.salaryMax > 0 ? job.salaryMax.toString() : '';

      if (job.imagePath.isNotEmpty && ImageService.isBase64(job.imagePath)) {
        _existingImageBase64 = job.imagePath;
      }

      _requirements = List.from(job.requirements);
      if (_jobTypes.contains(job.jobType)) {
        _jobType = job.jobType;
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
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

  Future<void> _saveJob() async {
    if (titleCtrl.text.isEmpty || descCtrl.text.isEmpty) {
      _showSnackBar('Por favor completa título y descripción', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      String imageBase64 = _existingImageBase64 ?? '';

      if (_imageFile != null) {
        imageBase64 = ImageService.imageToBase64(_imageFile!);
      }

      final jobData = {
        'title': titleCtrl.text,
        'description': descCtrl.text,
        'company': loggedUser!.name,
        'location': locationCtrl.text.isEmpty ? 'Huancayo' : locationCtrl.text,
        'phone': phoneCtrl.text,
        'employerEmail': loggedUser!.email,
        'salaryMin': double.tryParse(salaryMinCtrl.text) ?? 0,
        'salaryMax': double.tryParse(salaryMaxCtrl.text) ?? 0,
        'imagePath': imageBase64,
        'requirements': _requirements,
        'jobType': _jobType,
        if (_selectedLat != null) 'lat': _selectedLat,
        if (_selectedLng != null) 'lng': _selectedLng,
      };

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection('wanka_jobs')
            .doc(widget.jobToEdit!.id)
            .update(jobData);
      } else {
        jobData['applicants'] = [];
        jobData['postedDate'] = DateTime.now().toIso8601String();
        await FirebaseFirestore.instance.collection('wanka_jobs').add(jobData);
      }

      if (mounted) {
        _showSnackBar(
          isEditing ? '✓ Empleo actualizado' : '✓ Empleo publicado',
          isError: false,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
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

    // Accent color for this screen (green-based)
    final accent = isDark ? const Color(0xFF66BB6A) : Colors.green.shade600;
    final accentLight =
        isDark ? const Color(0xFF66BB6A) : Colors.green.shade400;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withOpacity(isDark ? 0.08 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.secondary.withOpacity(isDark ? 0.05 : 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildModernHeader(theme, cs, isDark),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(_fadeAnimation),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildImageSection(theme, cs, isDark, accent),
                            const SizedBox(height: 28),

                            // ── Información Básica ──
                            _buildSectionCard(
                              theme,
                              cs,
                              isDark,
                              accent,
                              title: 'Información Básica',
                              icon: Icons.info_outline_rounded,
                              children: [
                                _buildPremiumTextField(
                                  controller: titleCtrl,
                                  label: 'Título del puesto',
                                  icon: Icons.work_outline_rounded,
                                  hint: 'Ej: Desarrollador Flutter Senior',
                                  theme: theme,
                                  cs: cs,
                                  isDark: isDark,
                                  accent: accentLight,
                                ),
                                const SizedBox(height: 14),
                                _buildPremiumTextField(
                                  controller: descCtrl,
                                  label: 'Descripción del empleo',
                                  icon: Icons.description_outlined,
                                  maxLines: 4,
                                  hint: 'Describe las responsabilidades...',
                                  theme: theme,
                                  cs: cs,
                                  isDark: isDark,
                                  accent: accentLight,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Detalles del Empleo ──
                            _buildSectionCard(
                              theme,
                              cs,
                              isDark,
                              accent,
                              title: 'Detalles del Empleo',
                              icon: Icons.list_alt_rounded,
                              children: [
                                _buildJobTypeDropdown(
                                  theme,
                                  cs,
                                  isDark,
                                  accentLight,
                                ),
                                const SizedBox(height: 14),
                                _buildLocationPicker(
                                  theme,
                                  cs,
                                  isDark,
                                  accentLight,
                                ),
                                const SizedBox(height: 14),
                                _buildPremiumTextField(
                                  controller: phoneCtrl,
                                  label: 'Teléfono de contacto',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  theme: theme,
                                  cs: cs,
                                  isDark: isDark,
                                  accent: accentLight,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Matching & Requisitos ──
                            _buildSectionCard(
                              theme,
                              cs,
                              isDark,
                              accent,
                              title: 'Matching & Requisitos',
                              icon: Icons.auto_awesome_outlined,
                              children: [
                                _buildRequirementsInput(
                                  theme,
                                  cs,
                                  isDark,
                                  accent,
                                  accentLight,
                                ),
                                if (_requirements.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _buildRequirementsChips(
                                    theme,
                                    cs,
                                    isDark,
                                    accent,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Remuneración ──
                            _buildSectionCard(
                              theme,
                              cs,
                              isDark,
                              accent,
                              title: 'Remuneración',
                              icon: Icons.payments_outlined,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildPremiumTextField(
                                        controller: salaryMinCtrl,
                                        label: 'Mínimo (S/)',
                                        icon: Icons.remove_circle_outline,
                                        keyboardType: TextInputType.number,
                                        theme: theme,
                                        cs: cs,
                                        isDark: isDark,
                                        accent: accentLight,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _buildPremiumTextField(
                                        controller: salaryMaxCtrl,
                                        label: 'Máximo (S/)',
                                        icon: Icons.add_circle_outline,
                                        keyboardType: TextInputType.number,
                                        theme: theme,
                                        cs: cs,
                                        isDark: isDark,
                                        accent: accentLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),
                            _buildSubmitButton(theme, cs, isDark, accent),
                            const SizedBox(height: 16),
                          ],
                        ),
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

  Widget _buildModernHeader(ThemeData theme, ColorScheme cs, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
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
            isEditing ? 'Editar Empleo' : 'Publicar Empleo',
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
          // Section header
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

  Widget _buildImageSection(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? cs.outlineVariant : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: _buildImageContent(accent),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
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
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobTypeDropdown(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : const Color(0xFFF0F0F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _jobType,
          dropdownColor: isDark ? cs.surfaceContainerHighest : Colors.white,
          style: TextStyle(color: cs.onSurface, fontSize: 15),
          decoration: InputDecoration(
            label: Text(
              'Tipo de empleo',
              style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
            icon: Icon(Icons.timer_outlined, color: accent),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          items:
              _jobTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getJobTypeLabel(type)),
                );
              }).toList(),
          onChanged: (val) => setState(() => _jobType = val!),
        ),
      ),
    );
  }

  String _getJobTypeLabel(String type) {
    switch (type) {
      case 'profesional':
        return 'Profesional';
      case 'temporal':
        return 'Temporal';
      case 'medio-tiempo':
        return 'Medio Tiempo';
      case 'por-obra':
        return 'Por Obra';
      case 'remoto':
        return 'Remoto';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  Widget _buildLocationPicker(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<LocationPickerResult>(
          context,
          MaterialPageRoute(
            builder:
                (_) => LocationPickerScreen(
                  initialAddress:
                      locationCtrl.text.isNotEmpty ? locationCtrl.text : null,
                  initialLat: _selectedLat,
                  initialLng: _selectedLng,
                ),
          ),
        );

        if (result != null) {
          setState(() {
            locationCtrl.text = result.address;
            _selectedLat = result.latitude;
            _selectedLng = result.longitude;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHighest : const Color(0xFFF0F0F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.map_outlined, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locationCtrl.text.isNotEmpty
                        ? locationCtrl.text
                        : 'Seleccionar en Mapa',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          locationCtrl.text.isNotEmpty
                              ? FontWeight.w600
                              : FontWeight.w500,
                      color:
                          locationCtrl.text.isNotEmpty
                              ? cs.onSurface
                              : cs.onSurface.withOpacity(0.5),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_selectedLat != null && _selectedLng != null)
                    Text(
                      '${_selectedLat!.toStringAsFixed(4)}, ${_selectedLng!.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.4),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsInput(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
    Color accentLight,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _buildPremiumTextField(
            controller: requirementCtrl,
            label: 'Agregar requisito',
            icon: Icons.check_circle_outline,
            hint: 'Ej: 2 años de exp.',
            theme: theme,
            cs: cs,
            isDark: isDark,
            accent: accentLight,
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: accent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _addRequirement,
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
        style: TextStyle(color: cs.onSurface, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: accent, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          labelStyle: TextStyle(color: cs.onSurface.withOpacity(0.5)),
          hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.3)),
          floatingLabelStyle: TextStyle(
            color: accent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(Color accent) {
    if (_imageFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_imageFile!, fit: BoxFit.cover),
          _buildEditOverlay(),
        ],
      );
    } else if (_existingImageBase64 != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            ImageService.base64ToImage(_existingImageBase64!),
            fit: BoxFit.cover,
          ),
          _buildEditOverlay(),
        ],
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withOpacity(0.7), accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: 36,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  Widget _buildEditOverlay() {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2)),
      child: const Center(
        child: Icon(Icons.edit, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildSubmitButton(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [accent.withOpacity(0.9), accent.withOpacity(0.7)]
                  : [Colors.green.shade600, Colors.green.shade800],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(isDark ? 0.2 : 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _saveJob,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child:
            isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isEditing ? Icons.save_outlined : Icons.publish_outlined,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'GUARDAR CAMBIOS' : 'PUBLICAR EMPLEO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  void _addRequirement() {
    final req = requirementCtrl.text.trim();
    if (req.isNotEmpty && !_requirements.contains(req)) {
      setState(() {
        _requirements.add(req);
        requirementCtrl.clear();
      });
    }
  }

  void _removeRequirement(String req) {
    setState(() {
      _requirements.remove(req);
    });
  }

  Widget _buildRequirementsChips(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _requirements.map((req) {
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
                    req,
                    style: TextStyle(
                      color: isDark ? accent : Colors.green.shade800,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _removeRequirement(req),
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

  @override
  void dispose() {
    _animationController.dispose();
    titleCtrl.dispose();
    descCtrl.dispose();
    locationCtrl.dispose();
    phoneCtrl.dispose();
    salaryMinCtrl.dispose();
    salaryMaxCtrl.dispose();
    requirementCtrl.dispose();
    super.dispose();
  }
}
