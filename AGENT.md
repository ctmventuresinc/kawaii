# Kawaii App - Development Guide

## 🏗️ Architecture & Code Organization

### Recent Refactoring (June 2025)
- **Extracted ButtonStyles** from `RandomPhotoView.swift` to `ButtonStyles.swift`
- **Reduced main view file** from 1700+ lines to ~1580 lines
- **Improved separation of concerns** - UI components are now modular and reusable

### File Structure
```
kawaii/
├── RandomPhotoView.swift       # Main view (should be further refactored)
├── ButtonStyles.swift          # Reusable button style components
├── BackgroundRemover.swift     # AI background removal functionality
└── Assets/                     # Images, wallpapers, sounds
```

## 🚨 Critical Refactoring Needed

### 1. **RandomPhotoView.swift is still too large (1580 lines)**
**Recommended splits:**
- `PhotoManager.swift` - Extract the entire PhotoManager class
- `PhotoItem.swift` - Extract PhotoItem struct and related models
- `SoundManager.swift` - Extract audio playback functionality  
- `DragGestureHandler.swift` - Extract drag/drop logic
- `AnimationHelpers.swift` - Extract animation state and functions

### 2. **Performance Optimizations Applied**
- ✅ **All Photos framework operations** moved to background queues
- ✅ **Vision framework** (face detection, background removal) on background threads
- ✅ **Main thread** only for UI updates
- ✅ **High-quality image loading** (2700px source → 153-234px display)

### 3. **UI Components Architecture**
- ✅ **ButtonStyles.swift** - Clean, reusable button components
- ✅ **ActivityView** - Standardized share sheet implementation
- ⚠️ **More extraction needed** - Custom shapes, filters, animations

## 🧪 Testing & Development

### Build Commands
```bash
# Build and run
cmd+r

# Check for issues
# Use Xcode diagnostics panel
```

### Performance Testing
- **No UI hangs** - All heavy operations on background queues
- **Responsive buttons** - Loading states with smooth animations  
- **Memory efficient** - High-res loading with proper disposal

## 📋 Code Standards

### 1. **File Organization**
- **Single responsibility** - One main purpose per file
- **Reusable components** - Extract to separate files
- **Maximum 500 lines** per file (current main view violates this)

### 2. **Performance Requirements**
- **All Photos/Vision framework calls** must be on background queues
- **UI updates only** on main thread
- **No blocking operations** on main thread

### 3. **Component Design**
- **ButtonStyles** - Separate file, protocol-based
- **ViewModels** - Extract business logic from views
- **Models** - Separate data structures

## 🎯 Next Priority Refactors

1. **Extract PhotoManager** (~200 lines) to separate file
2. **Extract PhotoItem models** (~100 lines) to separate file  
3. **Extract drag/drop logic** (~150 lines) to separate handler
4. **Extract sound management** (~50 lines) to separate file
5. **Break down main view** into smaller, focused components

## 💡 Development Philosophy

**"We are not junior juvenile devs"** - Always consider:
- **Separation of concerns** before adding code
- **Reusability** of components  
- **File organization** and architecture
- **Performance implications** of main thread usage
- **Maintainability** over quick fixes

---
*Last updated: June 22, 2025*
