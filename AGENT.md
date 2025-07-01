# Kawaii App - Development Guide

## 🏛️ Architecture & Patterns (Priority #1)

### Current Architecture Overview
```
kawaii/
├── ViewModels/
│   ├── PhotoItemsViewModel.swift    # Core photo logic (639 lines - NEEDS REFACTORING)
│   ├── PhotoViewModel.swift         # Photo fetching logic
│   └── DateSelectionViewModel.swift # Date navigation
├── Services/
│   ├── PhotoTypeDecisionService.swift  # Centralized photo type percentages
│   ├── SoundService.swift             # Audio playback management
│   ├── FeatureFlags.swift             # Feature toggles & app store review mode
│   ├── BackgroundRemover.swift        # AI background removal
│   └── ShareService.swift             # Share functionality
├── Components/                      # Reusable UI components
├── Models/                         # Data structures
├── Utilities/                      # Helper functions
└── RandomPhotoView.swift           # Main view (671 lines - manageable)
```

### 🔧 **IMPLEMENTED PATTERNS**

#### 1. **Generic Retry Pattern** ✅
**Problem Solved:** Three similar retry functions for different photo types  
**Solution:** Single `tryMultiplePhotosWithRetry()` with closure-based photo processors
```swift
tryMultiplePhotosWithRetry(
    photoType: "regular",
    photoProcessor: { asset, bgRemover, soundSvc, completion in
        // Custom processing logic
    }
)
```

#### 2. **Service Layer Pattern** ✅
- **PhotoTypeDecisionService** - Single source of truth for photo percentages
- **SoundService** - Centralized audio management
- **FeatureFlags** - Configuration management
- **BackgroundRemover** - AI processing abstraction

#### 3. **MVVM Pattern** ✅
- **ViewModels** handle business logic
- **Views** only handle UI state
- Clear separation of concerns

#### 4. **Feature Flag Pattern** ✅
```swift
FeatureFlags.shared.appStoreReviewMode  // Disables sounds, changes background
FeatureFlags.shared.preventDuplicatePhotos  // Photo deduplication
```

### 🚨 **URGENT REFACTORING NEEDED**

#### **PhotoItemsViewModel.swift (639 lines) - VIOLATES SINGLE RESPONSIBILITY**
**Recommended extractions:**
```
PhotoItemsViewModel (639 lines) →
├── PhotoItemFactory.swift        (~200 lines) - Photo creation logic
├── PhotoRetryService.swift       (~100 lines) - Retry logic coordination  
├── FaceDetectionService.swift    (~100 lines) - Face detection & cropping
├── PhotoLibraryService.swift     (~150 lines) - PHAsset fetching & filtering
└── PhotoItemsViewModel.swift     (~89 lines) - Pure view state management
```

### 🎯 **AVAILABLE ARCHITECTURAL PATTERNS**

#### **Enterprise Patterns**
- **Repository Pattern** - Abstract data access (PhotoRepository)
- **Use Cases/Interactors** - Clean Architecture business logic
- **Dependency Injection** - Loose coupling with protocols
- **Coordinator Pattern** - Navigation flow management
- **Command Pattern** - Encapsulate photo operations
- **Observer Pattern** - Reactive photo updates
- **Factory Pattern** - PhotoItem creation strategies

#### **iOS-Specific Patterns**  
- **Combine/Publisher** - Reactive photo streams
- **AsyncSequence** - Modern async photo processing
- **Actor Pattern** - Thread-safe photo management
- **Protocol-Oriented Programming** - Swift interfaces
- **Result Type** - Explicit error handling

#### **Organization Patterns**
- **Feature Modules** - Group by functionality
- **Layer Architecture** - UI → Business → Data
- **Hexagonal Architecture** - Ports & adapters
- **Clean Architecture** - Dependency inversion

## 🎨 **Current App State**

### Photo Configuration
- **Photo Types**: 100% regular photos (Option J)
- **Photo Sizes**: 150-500px (no frames), 153-234px (with frames)  
- **Background Removal**: Required for ALL photos (no full originals ever shown)
- **Retry Logic**: Up to 10 attempts per photo type until cutout succeeds

### Color System
- **Framed Photos**: 13 color combinations (background + stroke + filter from 3rd color)
- **Regular Photos**: Only `none` or `blackAndWhite` filters (50/50)
- **Filter Colors**: Red (#FF4757), Pink (#FF6B9D), Orange (#FF8C42) + custom frame colors

### App Store Review Mode
- **appStoreReviewMode = true** currently active
- **Changes**: All sounds OFF, blue background (vs wallpaper)
- **Purpose**: Clean, silent experience for App Store approval

## 🔧 **Build & Development**

### Commands
```bash
# Build and run
cmd+r

# Check diagnostics  
# Use Xcode diagnostics panel
```

### Performance Standards
- ✅ **All Photos/Vision framework** operations on background queues
- ✅ **Main thread** only for UI updates  
- ✅ **High-quality image loading** with proper disposal
- ✅ **Responsive UI** - No blocking operations

## 📋 **Code Standards & Philosophy**

### File Organization
- **Maximum 500 lines** per file (PhotoItemsViewModel violates this)
- **Single responsibility** principle
- **Protocol-oriented** abstractions
- **Reusable components** extracted to separate files

### Development Philosophy
**"We are not junior juvenile devs"** - Always:
1. **Consider refactoring FIRST** using architectural patterns
2. **Separate concerns** before adding features
3. **Use framework capabilities** (don't over-engineer)
4. **Prioritize maintainability** over quick fixes
5. **Extract reusable components**

## ⚠️ **Critical Lessons Learned**

### 1. **Photo Selection Logic**
**Issue**: App was showing full original images when background removal failed  
**Solution**: Implemented retry pattern with background removal validation
**Lesson**: Never compromise on core app requirements (transparency-only)

### 2. **Framework Over-Engineering** 
**Mistake**: Custom photo filtering logic  
**Solution**: Use PhotoKit predicates for database-level filtering
```swift
fetchOptions.predicate = NSPredicate(format: "NOT (mediaSubtypes & %d) != 0", 
                                   PHAssetMediaSubtype.photoScreenshot.rawValue)
```

### 3. **Code Duplication**
**Issue**: Three similar retry functions  
**Solution**: Generic retry pattern with closure-based processors
**Lesson**: Look for patterns and extract common logic immediately

## 🚀 **Next Architectural Priorities**

1. **Extract PhotoItemFactory** from PhotoItemsViewModel (~200 lines)
2. **Implement Repository Pattern** for photo data access
3. **Add Dependency Injection** for service management  
4. **Consider Clean Architecture** layers for complex features
5. **Protocol-based abstractions** for testability

## 🏗️ **Refactoring Approach**

When adding features:
1. **Identify architectural pattern** from options above
2. **Check if existing services** can be extended
3. **Consider extraction opportunities** if files >500 lines
4. **Use protocol abstractions** for loose coupling
5. **Test in isolation** with proper separation

---
*Last updated: December 30, 2025*
*Current state: 100% regular photos, background removal required, app store review mode active*
