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
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade700, Colors.green.shade50],
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
                    Text(
                      isEditing ? 'Editar Empleo' : 'Publicar Empleo',
                      style: const TextStyle(
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
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildImagePicker(),
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: titleCtrl,
                              label: 'Título del puesto',
                              icon: Icons.work_outline,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: descCtrl,
                              label: 'Descripción',
                              icon: Icons.description_outlined,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: descCtrl,
                              label: 'Descripción',
                              icon: Icons.description_outlined,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 16),

                            // Requirements Tag Input
                            const Text(
                              'Requisitos (Para mejor matching)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: requirementCtrl,
                                    label: 'Agregar requisito (ej: Inglés)',
                                    icon: Icons.fact_check_outlined,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _addRequirement,
                                  icon: const Icon(Icons.add_circle),
                                  color: Colors.green,
                                  iconSize: 40,
                                ),
                              ],
                            ),
                            if (_requirements.isNotEmpty)
                              const SizedBox(height: 8),
                            _buildRequirementsChips(),
                            const SizedBox(height: 16),

                            // Job Type Dropdown
                            DropdownButtonFormField<String>(
                              value: _jobType,
                              decoration: InputDecoration(
                                labelText: 'Tipo de empleo',
                                prefixIcon: Icon(
                                  Icons.work,
                                  color: Colors.green.shade700,
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items:
                                  _jobTypes.map((type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(type.toUpperCase()),
                                    );
                                  }).toList(),
                              onChanged:
                                  (val) => setState(() => _jobType = val!),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: locationCtrl,
                              label: 'Ubicación',
                              icon: Icons.location_on_outlined,
                              hint: 'Huancayo',
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: phoneCtrl,
                              label: 'Teléfono',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: salaryMinCtrl,
                                    label: 'Salario mín.',
                                    icon: Icons.attach_money,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: salaryMaxCtrl,
                                    label: 'Salario máx.',
                                    icon: Icons.attach_money,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            _buildSubmitButton(),
                          ],
                        ),
                      ),
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

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _buildImageContent(),
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
            colors: [Colors.green.shade300, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 60,
              color: Colors.white,
            ),
            SizedBox(height: 12),
            Text(
              'Toca para agregar imagen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEditOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
              ],
            ),
            child: Icon(Icons.edit, color: Colors.green.shade700, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.green.shade700),
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
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
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
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'GUARDAR CAMBIOS' : 'PUBLICAR EMPLEO',
                      style: const TextStyle(
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

  @override
  void dispose() {
    _animationController.dispose();
    titleCtrl.dispose();
    descCtrl.dispose();
    locationCtrl.dispose();
    phoneCtrl.dispose();
    salaryMinCtrl.dispose();
    salaryMaxCtrl.dispose();
    super.dispose();
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
            return Chip(
              label: Text(req),
              labelStyle: const TextStyle(color: Colors.white),
              backgroundColor: Colors.green.shade600,
              deleteIcon: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
              onDeleted: () => _removeRequirement(req),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          }).toList(),
    );
  }
}
