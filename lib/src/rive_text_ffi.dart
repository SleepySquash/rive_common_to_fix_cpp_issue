import 'dart:collection';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:rive_common/math.dart';
import 'package:rive_common/platform.dart' as rive;
import 'package:rive_common/rive_text.dart';

final DynamicLibrary nativeLib = _loadLibrary();

DynamicLibrary _loadLibrary() {
  // TODO: (Max) build and load librive_text.so for peon
  if (rive.Platform.instance.isTesting || true) {
    var paths = [
      '',
      '../../packages/rive_common/',
    ];
    if (Platform.isMacOS) {
      for (final path in paths) {
        try {
          return DynamicLibrary.open(
            '${path}shared_lib/build/bin/debug/librive_text.dylib',
          );

          // ignore: avoid_catching_errors
        } on ArgumentError catch (_) {}
      }
    } else if (Platform.isLinux) {
      for (final path in paths) {
        try {
          return DynamicLibrary.open(
            '${path}shared_lib/build/bin/debug/librive_text.so',
          );
          // ignore: avoid_catching_errors
        } on ArgumentError catch (_) {}
      }
    }
  }

  if (Platform.isAndroid) {
    return DynamicLibrary.open('librive_text.so');
  } else if (Platform.isWindows) {
    return DynamicLibrary.open('rive_common_plugin.dll');
  }
  return DynamicLibrary.process();
}

class FontAxisStruct extends Struct implements FontAxis {
  @override
  @Uint32()
  external int tag;
  @override
  @Float()
  external double min;
  @override
  @Float()
  external double def;
  @override
  @Float()
  external double max;

  @override
  String toString() => 'FontAxisStruct[$tag, $min, $def, $max]';

  @override
  String get name => FontTag.tagToName(tag);

  @override
  FontAxisCoord valueAt(double value) => FontAxisCoord(tag, value);
}

class PathPoint extends Struct {
  @Float()
  external double x;
  @Float()
  external double y;

  @override
  String toString() => '[$x, $y]';
}

class GlyphPathStruct extends Struct {
  external Pointer<Void> rawPath;
  external Pointer<PathPoint> points;
  external Pointer<Uint8> verbs;

  @Uint16()
  external int verbCount;
}

class GlyphLineNative extends Struct {
  @Uint32()
  external int startRun;

  @Uint32()
  external int startIndex;

  @Uint32()
  external int endRun;

  @Uint32()
  external int endIndex;

  @Float()
  external double startX;

  @Float()
  external double top;

  @Float()
  external double baseline;

  @Float()
  external double bottom;
}

class GlyphLineFFI extends GlyphLine {
  final GlyphLineNative nativeLine;

  GlyphLineFFI(this.nativeLine);

  @override
  double get baseline => nativeLine.baseline;

  @override
  double get bottom => nativeLine.bottom;

  @override
  int get endIndex => nativeLine.endIndex;

  @override
  int get endRun => nativeLine.endRun;

  @override
  int get startIndex => nativeLine.startIndex;

  @override
  int get startRun => nativeLine.startRun;

  @override
  double get startX => nativeLine.startX;

  @override
  double get top => nativeLine.top;
}

class SimpleLineList extends Struct {
  external Pointer<GlyphLineNative> data;
  @Uint64()
  external int size;
}

class SimpleLineDoubleList extends Struct {
  external Pointer<SimpleLineList> data;
  @Uint64()
  external int size;
}

class SimpleUint16Array extends Struct {
  external Pointer<Uint16> data;
  @Uint64()
  external int size;
}

class SimpleUint32Array extends Struct {
  external Pointer<Uint32> data;
  @Uint64()
  external int size;
}

class SimpleFloatArray extends Struct {
  external Pointer<Float> data;
  @Uint64()
  external int size;
}

class SimpleVec2DArray extends Struct {
  external Pointer<PathPoint> data;
  @Uint64()
  external int size;
}

class TextRunNative extends Struct {
  external Pointer<Void> font;
  @Float()
  external double size;
  @Float()
  external double lineHeight;
  @Float()
  external double letterSpacing;
  @Uint32()
  external int unicharCount;
  @Uint32()
  external int script;
  @Uint16()
  external int styleId;
  @Uint8()
  external int dir;
}

class FontAxisCoordNative extends Struct {
  @Uint32()
  external int tag;
  @Float()
  external double value;
}

class FontFeatureNative extends Struct {
  @Uint32()
  external int tag;
  @Uint32()
  external int value;
}

class SimpleGlyphRunArray extends Struct {
  external Pointer<GlyphRunNative> data;
  @Uint64()
  external int size;

  List<GlyphRunNative> toList() {
    var list = <GlyphRunNative>[];
    for (int i = 0; i < size; i++) {
      list.add(data.elementAt(i).ref);
    }
    return list;
  }
}

class GlyphRunNative extends Struct implements GlyphRun {
  external Pointer<Void> fontPtr;
  @Float()
  external double size;
  @Float()
  external double height;
  @Float()
  external double spacing;
  external SimpleUint16Array glyphs;
  external SimpleUint32Array textIndices;
  external SimpleFloatArray advances;
  external SimpleFloatArray xpos;
  external SimpleVec2DArray offsets;
  external SimpleUint32Array breaks;
  @override
  @Uint16()
  external int styleId;
  @Uint8()
  external int dir;

  @override
  double get fontSize => size;

  @override
  double get lineHeight => height;

  @override
  double get letterSpacing => spacing;

  @override
  int get glyphCount => glyphs.size;

  @override
  int glyphIdAt(int index) => glyphs.data.elementAt(index).value;

  @override
  Font get font => FontFFI(fontPtr);

  @override
  int textIndexAt(int index) => textIndices.data.elementAt(index).value;

  @override
  double advanceAt(int index) => advances.data.elementAt(index).value;

  @override
  double xAt(int index) => xpos.data.elementAt(index).value;

  @override
  Vec2D offsetAt(int index) {
    var ref = offsets.data.elementAt(index).ref;
    return Vec2D.fromValues(ref.x, ref.y);
  }

  @override
  TextDirection get direction => TextDirection.values[dir];
}

class DynamicTextRunArray extends Struct {
  external Pointer<GlyphRunNative> data;
  @Uint64()
  external int size;
}

class ParagraphNative extends Struct {
  external SimpleGlyphRunArray runs;
  @Uint8()
  external int direction;
}

class SimpleParagraphArray extends Struct {
  external Pointer<ParagraphNative> data;
  @Uint64()
  external int size;

  List<Paragraph> toList() {
    var list = <Paragraph>[];
    for (int i = 0; i < size; i++) {
      list.add(ParagraphFFI(data.elementAt(i).ref));
    }
    return list;
  }
}

class SimpleTagArray extends Struct {
  external Pointer<Uint32> data;
  @Uint64()
  external int size;

  List<TagFFI> toList() {
    var list = <TagFFI>[];
    for (int i = 0; i < size; i++) {
      list.add(TagFFI(data.elementAt(i).value));
    }
    return list;
  }
}

class SimpleAxisArray extends Struct {
  external Pointer<FontAxisStruct> data;
  @Uint64()
  external int size;

  List<FontAxis> toList() {
    var list = <FontAxis>[];
    for (int i = 0; i < size; i++) {
      list.add(data.elementAt(i).ref);
    }
    return list;
  }
}

class ParagraphFFI extends Paragraph {
  final ParagraphNative nativeParagraph;
  @override
  TextDirection get direction =>
      TextDirection.values[nativeParagraph.direction];

  @override
  final List<GlyphRun> runs;

  ParagraphFFI(this.nativeParagraph) : runs = nativeParagraph.runs.toList();
}

class ParagraphsListFFI extends ListBase<ParagraphFFI> {
  final SimpleParagraphArray nativeList;
  @override
  int get length => nativeList.size;

  ParagraphsListFFI._(this.nativeList);

  @override
  ParagraphFFI operator [](int index) =>
      ParagraphFFI(nativeList.data.elementAt(index).ref);

  @override
  void operator []=(int index, ParagraphFFI value) {
    throw UnsupportedError('Cannot set Paragraph on ParagraphList');
  }

  @override
  set length(int newLength) {
    throw UnsupportedError('Cannot set length on ParagraphList');
  }
}

class LineList extends ListBase<GlyphLine> {
  final SimpleLineList nativeList;

  LineList(this.nativeList);
  @override
  int get length => nativeList.size;

  @override
  GlyphLine operator [](int index) =>
      GlyphLineFFI(nativeList.data.elementAt(index).ref);

  @override
  void operator []=(int index, GlyphLine value) {
    throw UnsupportedError('Cannot set glyphline on LineList');
  }

  @override
  set length(int newLength) {
    throw UnsupportedError('Cannot set length on LineList');
  }
}

class LineDoubleList extends BreakLinesResult {
  final Pointer<SimpleLineDoubleList> nativeDoubleListPtr;
  final SimpleLineDoubleList nativeDoubleList;

  @override
  int get length => nativeDoubleList.size;

  LineDoubleList(this.nativeDoubleListPtr)
      : nativeDoubleList = nativeDoubleListPtr.ref;

  @override
  List<GlyphLine> operator [](int index) =>
      LineList(nativeDoubleList.data.elementAt(index).ref);

  @override
  void operator []=(int index, List<GlyphLine> value) {
    throw UnsupportedError('Cannot set list on LineDoubleList');
  }

  @override
  set length(int newLength) {
    throw UnsupportedError('Cannot set length on LineDoubleList');
  }

  @override
  void dispose() => deleteLines(nativeDoubleListPtr);
}

class TextShapeResultFFI extends TextShapeResult {
  final Pointer<SimpleParagraphArray> nativeResult;
  TextShapeResultFFI(this.nativeResult)
      : paragraphs = nativeResult.ref.toList();

  @override
  void dispose() {
    deleteShapeResult(nativeResult);
  }

  @override
  BreakLinesResult breakLines(double width, TextAlign alignment) {
    return LineDoubleList(
        breakLinesNative(nativeResult, width, alignment.index));
  }

  @override
  final List<Paragraph> paragraphs;
}

final Pointer<SimpleParagraphArray> Function(Pointer<Uint32> text,
        int textLength, Pointer<TextRunNative> runs, int runsLength) shapeText =
    nativeLib
        .lookup<
            NativeFunction<
                Pointer<SimpleParagraphArray> Function(Pointer<Uint32>, Uint64,
                    Pointer<TextRunNative>, Uint64)>>('shapeText')
        .asFunction();

final Pointer<SimpleTagArray> Function(
    Pointer<Void>
        font) fontFeatures = nativeLib
    .lookup<NativeFunction<Pointer<SimpleTagArray> Function(Pointer<Void>)>>(
        'fontFeatures')
    .asFunction();

final void Function(Pointer<SimpleTagArray> tags) deleteFontFeatures = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<SimpleTagArray>)>>(
        'deleteFontFeatures')
    .asFunction();

final Pointer<Void> Function(
  Pointer<Void> font,
  Pointer<FontAxisCoordNative> coords,
  int coordsLength,
  Pointer<FontFeatureNative> features,
  int featuresLength,
) makeFontWithOptions = nativeLib
    .lookup<
        NativeFunction<
            Pointer<Void> Function(
              Pointer<Void>,
              Pointer<FontAxisCoordNative>,
              Uint64,
              Pointer<FontFeatureNative>,
              Uint64,
            )>>('makeFontWithOptions')
    .asFunction();

final void Function(Pointer<SimpleParagraphArray> font) deleteShapeResult =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<SimpleParagraphArray>)>>(
            'deleteShapeResult')
        .asFunction();

final Pointer<SimpleLineDoubleList> Function(
        Pointer<SimpleParagraphArray>, double width, int align)
    breakLinesNative = nativeLib
        .lookup<
            NativeFunction<
                Pointer<SimpleLineDoubleList> Function(
                    Pointer<SimpleParagraphArray>, Float, Uint8)>>('breakLines')
        .asFunction();

final void Function(Pointer<SimpleLineDoubleList>) deleteLines = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<SimpleLineDoubleList>)>>(
        'deleteLines')
    .asFunction();

final Pointer<Void> Function(Pointer<Uint8> bytes, int count) makeFont =
    nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Uint8>, Uint64)>>(
            'makeFont')
        .asFunction();

final void Function(Pointer<Void> font) deleteFont = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>('deleteFont')
    .asFunction();

final GlyphPathStruct Function(
    Pointer<Void> font,
    int
        glyphId) makeGlyphPath = nativeLib
    .lookup<NativeFunction<GlyphPathStruct Function(Pointer<Void>, Uint16)>>(
        'makeGlyphPath')
    .asFunction();

final void Function(Pointer<Void> font) deleteGlyphPath = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>('deleteGlyphPath')
    .asFunction();

final void Function() init =
    nativeLib.lookup<NativeFunction<Void Function()>>('init').asFunction();

final Pointer<SimpleParagraphArray> Function(
        Pointer<Pointer<Void>> fonts, int fontsLength) setFallbackFontsNative =
    nativeLib
        .lookup<
            NativeFunction<
                Pointer<SimpleParagraphArray> Function(
                    Pointer<Pointer<Void>>, Uint64)>>('setFallbackFonts')
        .asFunction();

final int Function(Pointer<Void> font) fontAxisCount = nativeLib
    .lookup<NativeFunction<Uint16 Function(Pointer<Void>)>>('fontAxisCount')
    .asFunction();

final FontAxisStruct Function(Pointer<Void> font, int index) fontAxis =
    nativeLib
        .lookup<NativeFunction<FontAxisStruct Function(Pointer<Void>, Uint16)>>(
            'fontAxis')
        .asFunction();

final double Function(Pointer<Void> font, int axis) fontAxisValue = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>, Uint32)>>(
        'fontAxisValue')
    .asFunction();

final double Function(Pointer<Void> font) fontAscent = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>('fontAscent')
    .asFunction();

final double Function(Pointer<Void> font) fontDescent = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>('fontDescent')
    .asFunction();

class RawPathCommandWasm extends RawPathCommand {
  final Pointer<PathPoint> _points;

  RawPathCommandWasm._(
    RawPathVerb verb,
    this._points,
  ) : super(verb);

  @override
  Vec2D point(int index) {
    var ref = _points.elementAt(index).ref;
    return Vec2D.fromValues(ref.x, ref.y);
  }
}

RawPathVerb _verbFromNative(int nativeVerb) {
  switch (nativeVerb) {
    case 0:
      return RawPathVerb.move;
    case 1:
      return RawPathVerb.line;
    case 2:
      return RawPathVerb.quad;
    case 4:
      return RawPathVerb.cubic;
    case 5:
      return RawPathVerb.close;
    default:
      throw Exception('Unexpected nativeVerb: $nativeVerb');
  }
}

int _ptsAdvanceAfterVerb(RawPathVerb verb) {
  switch (verb) {
    case RawPathVerb.move:
      return 1;
    case RawPathVerb.line:
      return 1;
    case RawPathVerb.quad:
      return 2;
    case RawPathVerb.cubic:
      return 3;
    case RawPathVerb.close:
      return 0;
    default:
      throw Exception('Unexpected nativeVerb: $verb');
  }
}

int _ptsBacksetForVerb(RawPathVerb verb) {
  switch (verb) {
    case RawPathVerb.move:
      return 0;
    case RawPathVerb.line:
      return -1;
    case RawPathVerb.quad:
      return -1;
    case RawPathVerb.cubic:
      return -1;
    case RawPathVerb.close:
      return -1;
    default:
      throw Exception('Unexpected nativeVerb: $verb');
  }
}

class RawPathIterator extends Iterator<RawPathCommand> {
  final GlyphPathStruct _native;
  int _verbIndex = -1;
  int _ptIndex = -1;

  RawPathVerb _verb = RawPathVerb.move;

  RawPathIterator._(this._native);

  @override
  RawPathCommand get current => RawPathCommandWasm._(
        _verb,
        _native.points.elementAt(_ptIndex + _ptsBacksetForVerb(_verb)),
      );

  @override
  bool moveNext() {
    if (++_verbIndex < _native.verbCount) {
      _ptIndex += _ptsAdvanceAfterVerb(_verb);
      _verb = _verbFromNative(_native.verbs.elementAt(_verbIndex).value);
      return true;
    }
    return false;
  }
}

class RawPathFFI extends RawPath {
  final GlyphPathStruct _native;
  RawPathFFI._(this._native);

  @override
  Iterator<RawPathCommand> get iterator => RawPathIterator._(_native);

  @override
  void dispose() => deleteGlyphPath(_native.rawPath);
}

class FontAxisIterator extends Iterator<FontAxis> {
  final Pointer<Void> fontPtr;
  final int axisCount;
  int axisIndex = -1;

  FontAxisIterator(this.fontPtr) : axisCount = fontAxisCount(fontPtr);

  @override
  FontAxis get current => fontAxis(fontPtr, axisIndex);

  @override
  bool moveNext() => ++axisIndex < axisCount;
}

class _FontAxisList extends IterableMixin<FontAxis> {
  Pointer<Void> fontPtr;
  _FontAxisList(this.fontPtr);

  @override
  Iterator<FontAxis> get iterator => FontAxisIterator(fontPtr);
}

class TagFFI extends FontTag {
  @override
  final int tag;

  TagFFI(this.tag);

  @override
  String toString() => 'TagFFI($tag == ${FontTag.tagToName(tag)})';
}

/// A Font reference that should not be explicitly disposed by the user.
/// Returned while shaping.
class FontFFI extends Font {
  Pointer<Void> fontPtr;
  @override
  Iterable<FontAxis> get axes => _FontAxisList(fontPtr);

  @override
  double axisValue(int axisTag) => fontAxisValue(fontPtr, axisTag);

  double? _ascent;
  double? _descent;
  @override
  double get ascent => _ascent ??= fontAscent(fontPtr);
  @override
  double get descent => _descent ??= fontDescent(fontPtr);

  FontFFI(this.fontPtr);

  @override
  Iterable<FontTag> get features {
    var features = fontFeatures(fontPtr);
    var result = features.ref.toList();
    deleteFontFeatures(features);
    return result;
  }

  @override
  Font? withOptions(
      Iterable<FontAxisCoord> coords, Iterable<FontFeature> features) {
    // Allocate and copy to coords memory.
    var coordsMemory = calloc.allocate<FontAxisCoordNative>(
        coords.length * sizeOf<FontAxisCoordNative>());
    int coordIndex = 0;
    for (final coord in coords) {
      coordsMemory[coordIndex++]
        ..tag = coord.tag
        ..value = coord.value;
    }

    // Allocate and copy to features memory.
    var featuresMemory = calloc.allocate<FontFeatureNative>(
        features.length * sizeOf<FontFeatureNative>());
    int featureIndex = 0;
    for (final feature in features) {
      featuresMemory[featureIndex++]
        ..tag = feature.tag
        ..value = feature.value;
    }

    var result = makeFontWithOptions(
      fontPtr,
      coordsMemory,
      coords.length,
      featuresMemory,
      features.length,
    );
    // Free memory for structs passed into native that we no longer need.
    calloc.free(coordsMemory);
    calloc.free(featuresMemory);
    if (result == nullptr) {
      return null;
    }

    // Return a strong font as this was created on the heap.
    return StrongFontFFI(result);
  }

  @override
  RawPath getPath(int glyphId) {
    var glyphPath = makeGlyphPath(fontPtr, glyphId);
    return RawPathFFI._(glyphPath);
  }

  @override
  void dispose() {}

  @override
  TextShapeResult shape(String text, List<TextRun> runs) {
    var textUni = text.codeUnits;

    // Allocate and copy to runs memory.
    var runsMemory =
        calloc.allocate<TextRunNative>(runs.length * sizeOf<TextRunNative>());
    int runIndex = 0;
    for (final run in runs) {
      runsMemory[runIndex++]
        ..font = (run.font as FontFFI).fontPtr
        ..size = run.fontSize
        ..lineHeight = run.lineHeight
        ..letterSpacing = run.letterSpacing
        ..script = 0
        ..unicharCount = run.unicharCount
        ..styleId = run.styleId
        ..dir = 0;
    }

    // Allocate and copy to text buffer.
    var textBuffer = calloc.allocate<Uint32>(textUni.length * sizeOf<Uint32>());
    for (int i = 0; i < textUni.length; i++) {
      textBuffer[i] = textUni[i];
    }

    var shapeResult =
        shapeText(textBuffer, textUni.length, runsMemory, runs.length);

    // Free memory for structs passed into native that we no longer need.
    calloc.free(textBuffer);
    calloc.free(runsMemory);

    return TextShapeResultFFI(shapeResult);
  }
}

/// A Font created and owned by Dart code. User is expected to call
/// dispose to release the font when they are done with it.
class StrongFontFFI extends FontFFI {
  StrongFontFFI(Pointer<Void> ptr) : super(ptr);
  @override
  void dispose() => deleteFont(fontPtr);
}

Font? decodeFont(Uint8List bytes) {
  // Copy them to the native heap.
  var pointer = calloc.allocate<Uint8>(bytes.length);
  for (int i = 0; i < bytes.length; i++) {
    pointer[i] = bytes[i];
  }

  // Pass the pointer in to a native method.
  var result = makeFont(pointer, bytes.length);
  calloc.free(pointer);
  if (result == nullptr) {
    return null;
  }

  return StrongFontFFI(result);
}

Future<void> initFont() async {
  init();
}

void setFallbackFonts(List<Font> fonts) {
  // Allocate and copy to fonts list memory.
  var fontListMemory =
      calloc.allocate<Pointer<Void>>(fonts.length * sizeOf<Pointer<Void>>());
  int fontIndex = 0;
  for (final font in fonts) {
    fontListMemory[fontIndex++] = (font as FontFFI).fontPtr;
  }

  setFallbackFontsNative(fontListMemory, fonts.length);

  // Free memory for structs passed into native that we no longer need.
  calloc.free(fontListMemory);
}
