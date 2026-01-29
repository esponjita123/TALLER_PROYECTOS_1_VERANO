import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../datos/globales.dart';
import '../modelos/modelo_empleo.dart';
import '../servicios/servicio_imagen.dart';

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
  final requirementCtrl = TextEditingController(); // Nuevo controller

  File? _imageFile;
  String? _existingImageBase64;
  final ImagePicker _picker = ImagePicker();

  // Nuevos campos para ML
  List<String> _requirements = [];
  String _jobType = 'full-time';
  final List<String> _jobTypes = [
    'full-time',
    'part-time',
    'remote',
    'contract',
    'freelance',
  ];

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

      // Cargar requirements y jobType
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
        'requirements': _requirements, // Guardar requirements para ML
        'jobType': _jobType, // Guardar tipo de trabajo
      };

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection('wanka_jobs')
            .doc(widget.jobToEdit!.id)
            .update(jobData);
      } else {
        // jobData['requirements'] ya está incluido arriba
        // jobData['jobType'] ya está incluido arriba
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
    return Scaffold(
      backgroundColor: Colors.white,
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
                  colors: [Colors.green.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildModernHeader(),
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
                            _buildImageSection(),
                            const SizedBox(height: 32),

                            _buildSectionTitle(
                              'Información Básica',
                              Icons.info_outline,
                            ),
                            _buildPremiumTextField(
                              controller: titleCtrl,
                              label: 'Título del puesto',
                              icon: Icons.work_outline,
                              hint: 'Ej: Desarrollador Flutter Senior',
                            ),
                            const SizedBox(height: 16),
                            _buildPremiumTextField(
                              controller: descCtrl,
                              label: 'Descripción del empleo',
                              icon: Icons.description_outlined,
                              maxLines: 4,
                              hint: 'Describe las responsabilidades...',
                            ),

                            const SizedBox(height: 32),
                            _buildSectionTitle(
                              'Detalles del Empleo',
                              Icons.list_alt_outlined,
                            ),
                            _buildJobTypeDropdown(),
                            const SizedBox(height: 16),
                            _buildPremiumTextField(
                              controller: locationCtrl,
                              label: 'Ubicación',
                              icon: Icons.location_on_outlined,
                              hint: 'Ciudad o "Remoto"',
                            ),
                            const SizedBox(height: 16),
                            _buildPremiumTextField(
                              controller: phoneCtrl,
                              label: 'Teléfono de contacto',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),

                            const SizedBox(height: 32),
                            _buildSectionTitle(
                              'Matching & Requisitos',
                              Icons.auto_awesome_outlined,
                            ),
                            _buildRequirementsInput(),
                            _buildRequirementsChips(),

                            const SizedBox(height: 32),
                            _buildSectionTitle(
                              'Remuneración',
                              Icons.payments_outlined,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPremiumTextField(
                                    controller: salaryMinCtrl,
                                    label: 'Mínimo (S/)',
                                    icon: Icons.remove_circle_outline,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildPremiumTextField(
                                    controller: salaryMaxCtrl,
                                    label: 'Máximo (S/)',
                                    icon: Icons.add_circle_outline,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 48),
                            _buildSubmitButton(),
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

  Widget _buildModernHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.blueGrey.shade800,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            isEditing ? 'Editar Empleo' : 'Publicar Empleo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey.shade900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green.shade600),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.green.shade700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _buildImageContent(),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.camera_alt,
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

  Widget _buildJobTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _jobType,
          style: TextStyle(color: Colors.blueGrey.shade800, fontSize: 15),
          decoration: InputDecoration(
            label: const Text('Tipo de empleo'),
            icon: Icon(Icons.timer_outlined, color: Colors.green.shade400),
            border: InputBorder.none,
          ),
          items:
              _jobTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
          onChanged: (val) => setState(() => _jobType = val!),
        ),
      ),
    );
  }

  Widget _buildRequirementsInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _buildPremiumTextField(
            controller: requirementCtrl,
            label: 'Agregar requisito',
            icon: Icons.check_circle_outline,
            hint: 'Ej: 2 años de exp.',
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: _addRequirement,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              height: 56,
              width: 56,
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
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
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.blueGrey.shade900, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.green.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          floatingLabelStyle: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
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
            colors: [Colors.green.shade300, Colors.green.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: 40,
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

  Widget _buildSubmitButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 12,
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
            borderRadius: BorderRadius.circular(16),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
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

  Widget _buildRequirementsChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _requirements.map((req) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    req,
                    style: TextStyle(
                      color: Colors.green.shade800,
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
                      color: Colors.green.shade600,
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
