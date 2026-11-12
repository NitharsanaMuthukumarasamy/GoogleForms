import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/lecture_model.dart';
import '../controllers/lecture_controller.dart';

class CreateEditLectureScreen extends ConsumerStatefulWidget {
  final String? lectureId;

  const CreateEditLectureScreen({super.key, this.lectureId});

  @override
  ConsumerState<CreateEditLectureScreen> createState() => _CreateEditLectureScreenState();
}

class _CreateEditLectureScreenState extends ConsumerState<CreateEditLectureScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _speakerNameController = TextEditingController();
  final _designationController = TextEditingController();
  final _companyController = TextEditingController();
  final _venueController = TextEditingController();
  final _departmentController = TextEditingController();
  final _academicYearController = TextEditingController();
  final _responseTargetController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  LectureStatus _selectedStatus = LectureStatus.draft;
  bool _isInitialized = false;

  final List<String> _departmentSuggestions = [
    'MCA',
    'B.Sc. Computer Systems and Design',
    'BCA',
    'B.Sc. Computer Science',
    'Information Technology',
    'Computer Science & Engineering',
    'All Departments',
  ];

  final List<String> _academicYearSuggestions = [
    '2026-2027',
    '2025-2026',
    '2024-2025',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.lectureId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final defaultYear = ref.read(settingsControllerProvider).defaultAcademicYear;
        if (defaultYear.isNotEmpty && _academicYearController.text.isEmpty) {
          setState(() {
            _academicYearController.text = defaultYear;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _speakerNameController.dispose();
    _designationController.dispose();
    _companyController.dispose();
    _venueController.dispose();
    _departmentController.dispose();
    _academicYearController.dispose();
    _responseTargetController.dispose();
    super.dispose();
  }

  void _populateExistingLecture(Lecture lecture) {
    if (_isInitialized) return;
    _titleController.text = lecture.title;
    _speakerNameController.text = lecture.speakerName;
    _designationController.text = lecture.designation;
    _companyController.text = lecture.company;
    _venueController.text = lecture.venue;
    _departmentController.text = lecture.department;
    _academicYearController.text = lecture.academicYear;
    if (lecture.responseTarget != null) {
      _responseTargetController.text = lecture.responseTarget.toString();
    }
    _selectedDateTime = lecture.dateTime;
    _selectedStatus = lecture.status;
    _isInitialized = true;
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryNavy,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryNavy,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.lectureId != null;
    final targetVal = int.tryParse(_responseTargetController.text.trim());

    final lecture = Lecture(
      id: widget.lectureId ?? '',
      title: _titleController.text.trim(),
      speakerName: _speakerNameController.text.trim(),
      designation: _designationController.text.trim(),
      company: _companyController.text.trim(),
      dateTime: _selectedDateTime,
      venue: _venueController.text.trim(),
      department: _departmentController.text.trim(),
      academicYear: _academicYearController.text.trim(),
      status: _selectedStatus,
      createdAt: DateTime.now(),
      responseTarget: targetVal,
    );

    final actionController = ref.read(lectureActionControllerProvider.notifier);

    if (isEdit) {
      final success = await actionController.updateLecture(lecture);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lecture updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update lecture. Check permissions.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } else {
      final newId = await actionController.createLecture(lecture);
      if (mounted) {
        if (newId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lecture created successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create lecture.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.lectureId != null;
    final actionState = ref.watch(lectureActionControllerProvider);
    final isLoading = actionState.isLoading;

    // In edit mode, load existing lecture details
    if (isEdit && !_isInitialized) {
      final lectureAsync = ref.watch(lectureDetailProvider(widget.lectureId!));
      lectureAsync.whenData((lecture) {
        if (lecture != null) {
          _populateExistingLecture(lecture);
        }
      });
    }

    final formattedDateTime =
        DateFormat('EEEE, MMM dd, yyyy • hh:mm a').format(_selectedDateTime);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Lecture' : 'New Alumni Lecture'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Toggle (Draft / Active / Closed)
              _buildSectionCard(
                title: 'Lifecycle Status',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Setting to "Active" allows students to scan the QR code and submit responses.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<LectureStatus>(
                      segments: const [
                        ButtonSegment(
                          value: LectureStatus.draft,
                          label: Text('Draft'),
                          icon: Icon(Icons.edit_note),
                        ),
                        ButtonSegment(
                          value: LectureStatus.active,
                          label: Text('Active'),
                          icon: Icon(Icons.play_circle_filled),
                        ),
                        ButtonSegment(
                          value: LectureStatus.closed,
                          label: Text('Closed'),
                          icon: Icon(Icons.lock_clock),
                        ),
                      ],
                      selected: {_selectedStatus},
                      onSelectionChanged: (Set<LectureStatus> newSelection) {
                        setState(() {
                          _selectedStatus = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            switch (_selectedStatus) {
                              case LectureStatus.active:
                                return AppColors.success.withOpacity(0.15);
                              case LectureStatus.draft:
                                return AppColors.warning.withOpacity(0.18);
                              case LectureStatus.closed:
                                return AppColors.primaryNavy.withOpacity(0.12);
                            }
                          }
                          return Colors.transparent;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lecture Details
              _buildSectionCard(
                title: 'Session Information',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Lecture Title *',
                        hintText: 'e.g., Cloud Architecture & Modern DevOps',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Date & Time Picker Tile
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDateTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: AppColors.primaryNavy),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date & Time *',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formattedDateTime,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryNavy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _venueController,
                      decoration: const InputDecoration(
                        labelText: 'Venue / Hall *',
                        hintText: 'e.g., Auditorium Hall B or Virtual Zoom',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      validator: (val) =>
                          val == null || val.trim().isEmpty ? 'Venue is required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Speaker Details
              _buildSectionCard(
                title: 'Alumni Speaker Details',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _speakerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Speaker Full Name *',
                        hintText: 'e.g., Priya Sundaram (Class of 2018)',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Speaker name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _designationController,
                      decoration: const InputDecoration(
                        labelText: 'Designation / Role *',
                        hintText: 'e.g., Senior Software Architect',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Designation is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _companyController,
                      decoration: const InputDecoration(
                        labelText: 'Company / Organization *',
                        hintText: 'e.g., Microsoft / Google / Startup',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Company is required'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Academic Context
              _buildSectionCard(
                title: 'Academic Classification',
                child: Column(
                  children: [
                    // Department Autocomplete / Dropdown field
                    TextFormField(
                      controller: _departmentController,
                      decoration: InputDecoration(
                        labelText: 'Organizing Department *',
                        hintText: 'e.g., MCA',
                        prefixIcon: const Icon(Icons.domain),
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (val) => _departmentController.text = val,
                          itemBuilder: (_) => _departmentSuggestions.map((dept) {
                            return PopupMenuItem(value: dept, child: Text(dept));
                          }).toList(),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Department is required'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Academic Year Field
                    TextFormField(
                      controller: _academicYearController,
                      decoration: InputDecoration(
                        labelText: 'Academic Year *',
                        hintText: 'e.g., 2026-2027',
                        prefixIcon: const Icon(Icons.school_outlined),
                        suffixIcon: PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (val) => _academicYearController.text = val,
                          itemBuilder: (_) => _academicYearSuggestions.map((yr) {
                            return PopupMenuItem(value: yr, child: Text(yr));
                          }).toList(),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Academic Year is required'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Response Target (Optional)
              _buildSectionCard(
                title: 'Response Target & Milestones (Optional)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Set an expected response target (e.g. 50 or 100). The admin will receive a push notification milestone when this target is achieved.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _responseTargetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target Response Count',
                        hintText: 'e.g., 100',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final numVal = int.tryParse(val.trim());
                          if (numVal == null || numVal <= 0) {
                            return 'Please enter a valid positive number';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Save Button
              ElevatedButton(
                onPressed: isLoading ? null : _handleSave,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isEdit ? Icons.save_rounded : Icons.check_circle_outline),
                          const SizedBox(width: 8),
                          Text(isEdit ? 'Save Changes' : 'Create Lecture Record'),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
