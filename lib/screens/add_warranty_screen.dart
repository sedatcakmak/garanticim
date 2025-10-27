import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:garanticim/services/ad_service.dart';
import 'package:garanticim/services/auth_service.dart';
import 'package:garanticim/widgets/responsive_dialog.dart';
import '../models/warranty_item.dart';
import '../services/firebase_service.dart';
import '../services/image_service.dart';
import '../services/notification_service.dart';
import '../services/categories_brands_loader.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/text_sizes.dart';
import '../utils/date_helpers.dart';

class AddWarrantyScreen extends StatefulWidget {
  final WarrantyItem? warranty;

  const AddWarrantyScreen({super.key, this.warranty});

  @override
  State<AddWarrantyScreen> createState() => _AddWarrantyScreenState();
}

class _AddWarrantyScreenState extends State<AddWarrantyScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AuthService _authService = AuthService();
  final ImageService _imageService = ImageService();
  final NotificationService _notificationService = NotificationService();
  final CategoriesBrandsLoader _categoriesLoader = CategoriesBrandsLoader();

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _warrantyMonthsController =
      TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _totalCostController = TextEditingController();
  final TextEditingController _customCategoryController =
      TextEditingController();
  final TextEditingController _customBrandController = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  File? _productImage;
  File? _invoiceImage;
  String? _productImageUrl;
  String? _invoiceImageUrl;
  List<CategoryBrandData> _categories = [];
  List<String> _brandOptions = [];
  CategoryBrandData? _selectedCategory;
  String? _selectedBrandName;
  bool _isCategoryCustom = false;
  bool _isBrandCustom = false;
  bool _isCategoryLoading = true;
  String? _pendingCategoryName;
  String? _pendingBrandName;
  bool _isLoading = false;

  static const String _customOptionLabel = 'Diğer';

  bool get isEditing => widget.warranty != null;
  bool _adShown = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (isEditing) {
      _loadWarrantyData();
    }
  }

  Future<void> _showAdOnce() async {
    if (_adShown) return;

    final isPremium = await _authService.isPremiumUser();
    if (isPremium) return;

    await AdService().showAddWarrantyAd();
    _adShown = true;
  }

  void _loadWarrantyData() {
    final warranty = widget.warranty!;
    _productNameController.text = warranty.productName;
    _invoiceNumberController.text = warranty.invoiceNumber;
    _warrantyMonthsController.text = warranty.warrantyMonths.toString();
    _supplierController.text = warranty.supplier;
    _totalCostController.text = warranty.totalCost.toString();
    _purchaseDate = warranty.purchaseDate;
    _productImageUrl = warranty.productPhotoUrl;
    _invoiceImageUrl = warranty.invoicePhotoUrl;
    _pendingCategoryName = warranty.categoryName;
    _pendingBrandName = warranty.brandName;
    if (!_isCategoryLoading) {
      _applyPendingCategoryAndBrand();
    }
  }

  Future<void> _loadCategories() async {
    final data = await _categoriesLoader.loadCategories();
    final regularCategories = <CategoryBrandData>[];

    for (final category in data) {
      if (category.id != 'other') {
        regularCategories.add(category);
      }
    }

    if (!mounted) return;

    setState(() {
      _categories = regularCategories;
      _isCategoryLoading = false;
    });

    _applyPendingCategoryAndBrand();
  }

  void _applyPendingCategoryAndBrand() {
    if (!mounted) return;
    if (_isCategoryLoading) return;

    if (_pendingCategoryName != null && _pendingCategoryName!.isNotEmpty) {
      CategoryBrandData? matchedCategory;
      for (final category in _categories) {
        if (_normalizeText(category.name) ==
            _normalizeText(_pendingCategoryName!)) {
          matchedCategory = category;
          break;
        }
      }

      if (matchedCategory != null) {
        _selectCategory(matchedCategory);
      } else {
        _setCategoryToCustom(presetName: _pendingCategoryName);
      }
    }

    if (_pendingBrandName != null && _pendingBrandName!.isNotEmpty) {
      if (_isCategoryCustom || _brandOptions.isEmpty) {
        _setBrandToCustom(presetName: _pendingBrandName);
      } else {
        final normalizedPending = _normalizeText(_pendingBrandName!);
        String? matchedBrand;
        for (final brand in _brandOptions) {
          if (_normalizeText(brand) == normalizedPending) {
            matchedBrand = brand;
            break;
          }
        }

        if (matchedBrand != null) {
          _selectBrand(matchedBrand);
        } else {
          _setBrandToCustom(presetName: _pendingBrandName);
        }
      }
    }

    _pendingCategoryName = null;
    _pendingBrandName = null;
  }

  List<String> _prepareBrandOptions(List<String> brands) {
    final options = <String>[];
    for (final brand in brands) {
      final trimmed = brand.trim();
      if (trimmed.isEmpty) continue;
      if (_matchesCustomOption(trimmed)) continue;
      options.add(trimmed);
    }
    if (!options.any(_matchesCustomOption)) {
      options.add(_customOptionLabel);
    }
    return options;
  }

  void _selectCategory(CategoryBrandData category) {
    final brandOptions = _prepareBrandOptions(category.brands);

    setState(() {
      _selectedCategory = category;
      _isCategoryCustom = false;
      _customCategoryController.clear();
      _brandOptions = brandOptions;
      _selectedBrandName = null;
      _isBrandCustom = brandOptions.isEmpty;
      _customBrandController.clear();
    });

    if (_brandOptions.isEmpty) {
      _setBrandToCustom();
    }
  }

  void _setCategoryToCustom({String? presetName}) {
    setState(() {
      _selectedCategory = null;
      _isCategoryCustom = true;
      if (presetName != null) {
        _customCategoryController.text = presetName;
      } else {
        _customCategoryController.clear();
      }
      _brandOptions = [];
      _selectedBrandName = null;
      _isBrandCustom = true;
    });
  }

  void _selectBrand(String brand) {
    setState(() {
      _selectedBrandName = brand;
      _isBrandCustom = false;
      _customBrandController.clear();
    });
  }

  void _setBrandToCustom({String? presetName}) {
    setState(() {
      _selectedBrandName = null;
      _isBrandCustom = true;
      if (presetName != null) {
        _customBrandController.text = presetName;
      } else {
        _customBrandController.clear();
      }
    });
  }

  void _showCategoryPicker() {
    final options = _categories.map((category) => category.name).toList()
      ..add(_customOptionLabel);

    var initialIndex = 0;
    if (_isCategoryCustom) {
      initialIndex = options.length - 1;
    } else if (_selectedCategory != null) {
      final index = _categories.indexOf(_selectedCategory!);
      if (index >= 0) {
        initialIndex = index;
      }
    }

    var tempIndex = initialIndex;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => _buildPickerSheet(
        initialIndex: initialIndex,
        itemCount: options.length,
        itemLabelBuilder: (index) => options[index],
        onIndexChanged: (index) => tempIndex = index,
        onConfirm: () {
          if (tempIndex == options.length - 1) {
            _setCategoryToCustom();
          } else {
            _selectCategory(_categories[tempIndex]);
          }
        },
      ),
    );
  }

  void _showBrandPicker() {
    if (_brandOptions.isEmpty) {
      _setBrandToCustom();
      return;
    }

    final options = List<String>.from(_brandOptions);
    if (!options.any(_matchesCustomOption)) {
      options.add(_customOptionLabel);
    }

    var initialIndex = 0;
    if (_isBrandCustom || _selectedBrandName == null) {
      initialIndex = _isBrandCustom ? options.length - 1 : 0;
    } else {
      final index = options.indexWhere(
        (option) =>
            _normalizeText(option) == _normalizeText(_selectedBrandName!),
      );
      if (index >= 0) {
        initialIndex = index;
      }
    }

    var tempIndex = initialIndex;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => _buildPickerSheet(
        initialIndex: initialIndex,
        itemCount: options.length,
        itemLabelBuilder: (index) => options[index],
        onIndexChanged: (index) => tempIndex = index,
        onConfirm: () {
          if (tempIndex == options.length - 1) {
            _setBrandToCustom();
          } else {
            _selectBrand(options[tempIndex]);
          }
        },
      ),
    );
  }

  Widget _buildPickerSheet({
    required int initialIndex,
    required int itemCount,
    required String Function(int) itemLabelBuilder,
    required void Function(int) onIndexChanged,
    required VoidCallback onConfirm,
  }) {
    return Container(
      height: 300.h,
      color: AppColors.white,
      child: Column(
        children: [
          _buildPickerToolbar(
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () {
              Navigator.of(context).pop();
              onConfirm();
            },
          ),
          Expanded(
            child: CupertinoPicker(
              itemExtent: 36.h,
              scrollController: FixedExtentScrollController(
                initialItem: initialIndex,
              ),
              onSelectedItemChanged: (index) {
                onIndexChanged(index);
              },
              children: List.generate(itemCount, (index) {
                return Center(
                  child: Text(
                    itemLabelBuilder(index),
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: TextSizes.normal.sp,
                      color: AppColors.black,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerToolbar({
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
  }) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onCancel,
            child: Text('Iptal', style: TextStyle(color: AppColors.danger)),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onConfirm,
            child: Text('Tamam', style: TextStyle(color: AppColors.info)),
          ),
        ],
      ),
    );
  }

  bool _matchesCustomOption(String value) {
    return _normalizeText(value) == _normalizeText(_customOptionLabel);
  }

  String _normalizeText(String value) {
    final lower = value.toLowerCase();
    return lower
        .replaceAll('ı', 'i')
        .replaceAll('̇', '')
        .replaceAll('ğ', 'g')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r"[^a-z0-9]"), '');
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _invoiceNumberController.dispose();
    _warrantyMonthsController.dispose();
    _supplierController.dispose();
    _totalCostController.dispose();
    _customCategoryController.dispose();
    _customBrandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(top: 100.h),
              child: Stack(
                children: [
                  ListView(
                    padding: EdgeInsets.all(16.w),
                    children: [
                      _buildForm(),
                      SizedBox(height: 80.h),
                    ],
                  ),
                  if (_isLoading)
                    Container(
                      color: AppColors.black.withValues(alpha: 0.3),
                      child: Center(
                        child: CupertinoActivityIndicator(
                          radius: 20.r,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CustomAppBar(
              title: isEditing ? 'Garanti Düzenle' : 'Yeni Garanti Ekle',
              leading: RoundIconButton(
                icon: CupertinoIcons.back,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
              ),
              actions: const [],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final canPickBrand = !_isCategoryCustom && _brandOptions.isNotEmpty;
    final categoryPlaceholder = _isCategoryLoading
        ? 'Kategoriler yükleniyor...'
        : _isCategoryCustom
        ? _customOptionLabel
        : (_selectedCategory?.name ?? 'Kategori seçin');
    final brandPlaceholder = _isCategoryCustom
        ? _customOptionLabel
        : _isBrandCustom
        ? _customOptionLabel
        : (_selectedBrandName ??
              (canPickBrand ? 'Marka seçin' : 'Önce kategori seçin'));

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        children: [
          CustomTextField(
            label: 'Ürün Adı',
            placeholder: 'Ürün adını girin',
            icon: CupertinoIcons.cube_box,
            controller: _productNameController,
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            label: 'Kategori',
            placeholder: categoryPlaceholder,
            icon: CupertinoIcons.square_list,
            onTap: _isCategoryLoading ? null : _showCategoryPicker,
            enabled: !_isCategoryLoading,
          ),
          if (_isCategoryCustom) ...[
            SizedBox(height: 16.h),
            CustomTextField(
              label: 'Kategori Adı',
              placeholder: 'Kategori adını girin',
              icon: CupertinoIcons.pencil,
              controller: _customCategoryController,
            ),
          ],
          SizedBox(height: 16.h),
          CustomTextField(
            label: 'Marka',
            placeholder: brandPlaceholder,
            icon: CupertinoIcons.tag,
            onTap: canPickBrand ? _showBrandPicker : null,
            enabled: canPickBrand,
          ),
          if (_isBrandCustom) ...[
            SizedBox(height: 16.h),
            CustomTextField(
              label: 'Marka Adı',
              placeholder: 'Marka adını girin',
              icon: CupertinoIcons.pencil_ellipsis_rectangle,
              controller: _customBrandController,
            ),
          ],
          SizedBox(height: 16.h),
          CustomTextField(
            label: 'Satın Alma Tarihi',
            placeholder: DateHelpers.formatDate(_purchaseDate),
            icon: CupertinoIcons.calendar,
            onTap: _showDatePicker,
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            label: 'Fatura Numarası',
            placeholder: 'Fatura numarasını girin',
            icon: CupertinoIcons.doc_text,
            controller: _invoiceNumberController,
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            label: 'Garanti Süresi (Ay)',
            placeholder: 'Örnek: 24',
            icon: CupertinoIcons.clock,
            controller: _warrantyMonthsController,
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            label: 'Tedarikçi',
            placeholder: 'Tedarikçi adını girin',
            icon: CupertinoIcons.building_2_fill,
            controller: _supplierController,
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            label: 'Toplam Maliyet (TL)',
            placeholder: 'Örnek: 1500',
            icon: CupertinoIcons.money_dollar_circle,
            controller: _totalCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 20.h),
          ImagePickerWidget(
            label: 'Ürün Fotoğrafı',
            imageFile: _productImage,
            imageUrl: _productImageUrl,
            onPickImage: _pickProductImage,
            onRemoveImage: () {
              setState(() {
                _productImage = null;
                _productImageUrl = null;
              });
            },
          ),
          SizedBox(height: 20.h),
          ImagePickerWidget(
            label: 'Fatura Fotoğrafı',
            imageFile: _invoiceImage,
            imageUrl: _invoiceImageUrl,
            onPickImage: _pickInvoiceImage,
            onRemoveImage: () {
              setState(() {
                _invoiceImage = null;
                _invoiceImageUrl = null;
              });
            },
          ),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              color: AppColors.black,
              focusColor: AppColors.gray,
              onPressed: _isLoading ? null : _saveWarranty,
              borderRadius: BorderRadius.circular(16.r),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Text(
                isEditing ? 'Güncelle' : 'Kaydet',
                style: TextStyle(
                  color: AppColors.white,
                  fontFamily: AppFonts.family,
                  fontSize: TextSizes.box.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250.h,
        color: AppColors.white,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: Text(
                    'İptal',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                CupertinoButton(
                  child: Text('Tamam', style: TextStyle(color: AppColors.info)),
                  onPressed: () {
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _purchaseDate,
                maximumDate: DateTime.now(),
                onDateTimeChanged: (date) {
                  setState(() {
                    _purchaseDate = date;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProductImage() async {
    final image = await _imageService.pickImageFromGallery();
    if (image != null) {
      setState(() {
        _productImage = image;
      });
    }
  }

  Future<void> _pickInvoiceImage() async {
    final image = await _imageService.pickImageFromGallery();
    if (image != null) {
      setState(() {
        _invoiceImage = image;
      });
    }
  }

  Future<void> _saveWarranty() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) return;

      await _showAdOnce();

      String? productPhotoUrl = _productImageUrl;
      String? invoicePhotoUrl = _invoiceImageUrl;

      if (_productImage != null) {
        productPhotoUrl = await _imageService.uploadProductImage(
          _productImage!,
          userId,
        );
      }

      if (_invoiceImage != null) {
        invoicePhotoUrl = await _imageService.uploadInvoiceImage(
          _invoiceImage!,
          userId,
        );
      }

      final categoryName = _isCategoryCustom
          ? _customCategoryController.text.trim()
          : (_selectedCategory?.name ?? '');
      final brandName = _isBrandCustom
          ? _customBrandController.text.trim()
          : (_selectedBrandName ?? '');

      var warranty = WarrantyItem(
        categoryName: categoryName,
        brandName: brandName,
        id: isEditing ? widget.warranty!.id : '',
        userId: userId,
        productName: _productNameController.text.trim(),
        purchaseDate: _purchaseDate,
        invoiceNumber: _invoiceNumberController.text.trim(),
        invoicePhotoUrl: invoicePhotoUrl,
        warrantyMonths: int.parse(_warrantyMonthsController.text.trim()),
        supplier: _supplierController.text.trim(),
        productPhotoUrl: productPhotoUrl,
        totalCost: double.parse(_totalCostController.text.trim()),
        createdAt: isEditing ? widget.warranty!.createdAt : DateTime.now(),
        sharedAt: DateTime.now(),
        isLiked: false,
        isSharedSocial: isEditing ? widget.warranty!.isSharedSocial : false,
      );

      if (isEditing) {
        await _firebaseService.updateWarranty(warranty);
      } else {
        final newId = await _firebaseService.createWarranty(warranty);
        warranty = warranty.copyWith(id: newId);
      }

      try {
        await _notificationService.scheduleWarrantyNotifications(warranty);
      } catch (notificationError) {
        debugPrint('Notification scheduling error: $notificationError');
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _isLoading = false;
        });
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('Error saving warranty: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog();
      }
    }
  }

  bool _validateForm() {
    if (_productNameController.text.trim().isEmpty) {
      _showValidationError('Lütfen ürün adını girin!');
      return false;
    }
    if (_isCategoryLoading) {
      _showValidationError('Kategori listesi yükleniyor!');
      return false;
    }
    final categoryValue = _isCategoryCustom
        ? _customCategoryController.text.trim()
        : (_selectedCategory?.name ?? '');
    if (categoryValue.isEmpty) {
      _showValidationError('Lütfen kategori seçin!');
      return false;
    }
    final brandValue = _isBrandCustom
        ? _customBrandController.text.trim()
        : (_selectedBrandName ?? '');
    if (brandValue.isEmpty) {
      _showValidationError('Lütfen marka seçin!');
      return false;
    }
    if (_invoiceNumberController.text.trim().isEmpty) {
      _showValidationError('Lütfen fatura numarasını girin!');
      return false;
    }
    if (_warrantyMonthsController.text.trim().isEmpty) {
      _showValidationError('Lütfen garanti süresini girin!');
      return false;
    }
    if (_supplierController.text.trim().isEmpty) {
      _showValidationError('Lütfen tedarikçi adını girin!');
      return false;
    }
    if (_totalCostController.text.trim().isEmpty) {
      _showValidationError('Lütfen maliyeti girin!');
      return false;
    }
    return true;
  }

  void _showValidationError(String message) {
    ResponsiveDialog.show(
      context: context,
      title: 'Eksik Bilgi',
      titleColor: AppColors.warning,
      description: message,
    );
  }

  void _showSuccessDialog() {
    ResponsiveDialog.show(
      context: context,
      title: isEditing ? 'Güncellendi' : 'Kaydedildi',
      titleColor: AppColors.success,
      description: isEditing
          ? 'Garanti başarıyla güncellendi.'
          : 'Garanti başarıyla kaydedildi.',
      actions: [
        CupertinoDialogAction(
          child: const Text('Tamam'),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  void _showErrorDialog() {
    ResponsiveDialog.show(
      context: context,
      title: 'Hata',
      titleColor: AppColors.danger,
      description:
          'Garanti kaydedilirken bir hata oluştu. Lütfen tekrar deneyin.',
    );
  }
}
