import 'package:flutter/material.dart';
import 'pantalla_empleos.dart';

class AdvancedFiltersScreen extends StatefulWidget {
  final String? initialJobType;
  final double? initialMinSalary;
  final double? initialMaxSalary;
  final String? initialLocation;
  final bool initialRemoteOnly;

  const AdvancedFiltersScreen({
    super.key,
    this.initialJobType,
    this.initialMinSalary,
    this.initialMaxSalary,
    this.initialLocation,
    this.initialRemoteOnly = false,
  });

  @override
  State<AdvancedFiltersScreen> createState() => _AdvancedFiltersScreenState();
}

class _AdvancedFiltersScreenState extends State<AdvancedFiltersScreen> {
  String? selectedJobType;
  double? minSalary;
  double? maxSalary;
  String? selectedLocation;
  bool remoteOnly = false;

  final List<String> jobTypes = [
    'profesional',
    'temporal',
    'medio-tiempo',
    'por-obra',
    'remoto',
  ];

  final List<String> commonLocations = [
    'Huancayo',
    'Lima',
    'Arequipa',
    'Trujillo',
    'Cusco',
    'Chiclayo',
    'Piura',
    'Iquitos',
    'Remoto',
  ];

  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedJobType = widget.initialJobType;
    minSalary = widget.initialMinSalary;
    maxSalary = widget.initialMaxSalary;
    selectedLocation = widget.initialLocation;
    remoteOnly = widget.initialRemoteOnly;

    if (minSalary != null) {
      _minSalaryController.text = minSalary!.toInt().toString();
    }
    if (maxSalary != null) {
      _maxSalaryController.text = maxSalary!.toInt().toString();
    }
    if (selectedLocation != null) {
      _locationController.text = selectedLocation!;
    }
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

  IconData _getJobTypeIcon(String type) {
    switch (type) {
      case 'profesional':
        return Icons.work_outline;
      case 'temporal':
        return Icons.schedule;
      case 'medio-tiempo':
        return Icons.timelapse;
      case 'por-obra':
        return Icons.build_outlined;
      case 'remoto':
        return Icons.home_work_outlined;
      default:
        return Icons.work;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF64B5F6) : Colors.blue.shade700;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Filtros Avanzados',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: Text('Limpiar', style: TextStyle(color: accent)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Tipo de Empleo', Icons.category, cs, accent),
            const SizedBox(height: 12),
            _buildJobTypeSelector(theme, cs, isDark, accent),
            const SizedBox(height: 24),
            _buildSectionTitle(
              'Rango Salarial (S/)',
              Icons.payments_outlined,
              cs,
              accent,
            ),
            const SizedBox(height: 12),
            _buildSalaryRange(theme, cs, isDark, accent),
            const SizedBox(height: 24),
            _buildSectionTitle(
              'Ubicación',
              Icons.location_on_outlined,
              cs,
              accent,
            ),
            const SizedBox(height: 12),
            _buildLocationSelector(theme, cs, isDark, accent),
            const SizedBox(height: 24),
            _buildRemoteSwitch(theme, cs, isDark, accent),
            const SizedBox(height: 40),
            _buildApplyButton(accent),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    ColorScheme cs,
    Color accent,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildJobTypeSelector(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          jobTypes.map((type) {
            final isSelected = selectedJobType == type;
            return ChoiceChip(
              avatar: Icon(
                _getJobTypeIcon(type),
                size: 18,
                color:
                    isSelected ? Colors.white : cs.onSurface.withOpacity(0.6),
              ),
              label: Text(_getJobTypeLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedJobType = selected ? type : null;
                });
              },
              selectedColor: accent,
              labelStyle: TextStyle(
                color:
                    isSelected ? Colors.white : cs.onSurface.withOpacity(0.8),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor:
                  isDark ? cs.surfaceContainerHighest : theme.cardColor,
              side: BorderSide(color: isSelected ? accent : cs.outlineVariant),
            );
          }).toList(),
    );
  }

  Widget _buildSalaryRange(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
            isDark
                ? Border.all(color: cs.outlineVariant.withOpacity(0.5))
                : null,
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSalaryInput(
                  'Mínimo',
                  _minSalaryController,
                  (value) {
                    minSalary =
                        value.isNotEmpty ? double.tryParse(value) : null;
                  },
                  cs,
                  isDark,
                  accent,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '—',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
                ),
              ),
              Expanded(
                child: _buildSalaryInput(
                  'Máximo',
                  _maxSalaryController,
                  (value) {
                    maxSalary =
                        value.isNotEmpty ? double.tryParse(value) : null;
                  },
                  cs,
                  isDark,
                  accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: cs.outlineVariant.withOpacity(0.3),
              thumbColor: accent,
              overlayColor: accent.withOpacity(0.2),
            ),
            child: RangeSlider(
              values: RangeValues(minSalary ?? 0, maxSalary ?? 20000),
              min: 0,
              max: 20000,
              divisions: 20,
              labels: RangeLabels(
                'S/${(minSalary ?? 0).toInt()}',
                'S/${(maxSalary ?? 20000).toInt()}',
              ),
              onChanged: (values) {
                setState(() {
                  minSalary = values.start > 0 ? values.start : null;
                  maxSalary = values.end < 20000 ? values.end : null;
                  _minSalaryController.text =
                      minSalary?.toInt().toString() ?? '';
                  _maxSalaryController.text =
                      maxSalary?.toInt().toString() ?? '';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryInput(
    String label,
    TextEditingController controller,
    Function(String) onChanged,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: cs.onSurface.withOpacity(0.6)),
        prefixText: 'S/ ',
        prefixStyle: TextStyle(color: cs.onSurface.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildLocationSelector(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return Column(
      children: [
        TextField(
          controller: _locationController,
          style: TextStyle(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: 'Buscar ciudad...',
            hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.4)),
            prefixIcon: Icon(Icons.location_on, color: accent),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent),
            ),
            filled: true,
            fillColor: isDark ? cs.surfaceContainerHighest : theme.cardColor,
          ),
          onChanged: (value) {
            selectedLocation = value.isNotEmpty ? value : null;
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              commonLocations.map((location) {
                final isSelected =
                    selectedLocation?.toLowerCase() == location.toLowerCase();
                return ActionChip(
                  label: Text(location),
                  onPressed: () {
                    setState(() {
                      if (isSelected) {
                        selectedLocation = null;
                        _locationController.clear();
                      } else {
                        selectedLocation = location;
                        _locationController.text = location;
                      }
                    });
                  },
                  backgroundColor:
                      isSelected
                          ? accent.withOpacity(isDark ? 0.2 : 0.1)
                          : isDark
                          ? cs.surfaceContainerHighest
                          : theme.cardColor,
                  side: BorderSide(
                    color: isSelected ? accent : cs.outlineVariant,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? accent : cs.onSurface.withOpacity(0.8),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildRemoteSwitch(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border:
            isDark
                ? Border.all(color: cs.outlineVariant.withOpacity(0.5))
                : null,
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.home_work_outlined, color: accent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solo trabajos remotos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  'Mostrar solo empleos que permiten trabajo remoto',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: remoteOnly,
            onChanged: (value) {
              setState(() {
                remoteOnly = value;
              });
            },
            activeColor: accent,
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(Color accent) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(
            context,
            FilterResult(
              jobType: selectedJobType,
              minSalary: minSalary,
              maxSalary: maxSalary,
              location: remoteOnly ? 'remoto' : selectedLocation,
              remoteOnly: remoteOnly,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: const Text(
          'APLICAR FILTROS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      selectedJobType = null;
      minSalary = null;
      maxSalary = null;
      selectedLocation = null;
      remoteOnly = false;
      _minSalaryController.clear();
      _maxSalaryController.clear();
      _locationController.clear();
    });
  }

  @override
  void dispose() {
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
