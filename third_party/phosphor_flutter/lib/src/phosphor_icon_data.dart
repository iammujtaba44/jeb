library phosphor_flutter;

import 'package:flutter/widgets.dart';

// PATCHED (vendored copy): IconData is a `final` class in current Flutter, so
// these types can no longer extend it. They are now extension types wrapping a
// plain IconData — every value still IS an IconData at runtime and stays
// assignable wherever IconData is expected. The constructors are non-const
// (an extension-type redirect can't build a parameterized IconData in a const
// context), so the generated icon tables use `static final` instead of
// `static const`.

extension type PhosphorIconData._(IconData icon) implements IconData {
  PhosphorIconData(int codePoint, String style)
      : this._(
          IconData(
            codePoint,
            fontFamily: 'Phosphor$style',
            fontPackage: 'phosphor_flutter',
            matchTextDirection: true,
          ),
        );
}

extension type PhosphorFlatIconData._(IconData icon)
    implements PhosphorIconData {
  PhosphorFlatIconData(int codePoint, String style)
      : this._(PhosphorIconData(codePoint, style));
}

/// Extension types carry no extra storage, so the duotone secondary glyph no
/// longer rides on the icon value; the primary duotone glyph renders as
/// before (the plain [Icon] widget never used the secondary layer).
extension type PhosphorDuotoneIconData._(IconData icon)
    implements PhosphorIconData {
  PhosphorDuotoneIconData(int codePoint, PhosphorIconData secondary)
      : this._(PhosphorIconData(codePoint, 'Duotone'));
}
