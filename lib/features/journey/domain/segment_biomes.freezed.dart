// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'segment_biomes.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BiomeSpan {

 String get segmentId; String get biome; int get fromMeters; int get toMeters;
/// Create a copy of BiomeSpan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BiomeSpanCopyWith<BiomeSpan> get copyWith => _$BiomeSpanCopyWithImpl<BiomeSpan>(this as BiomeSpan, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BiomeSpan&&(identical(other.segmentId, segmentId) || other.segmentId == segmentId)&&(identical(other.biome, biome) || other.biome == biome)&&(identical(other.fromMeters, fromMeters) || other.fromMeters == fromMeters)&&(identical(other.toMeters, toMeters) || other.toMeters == toMeters));
}


@override
int get hashCode => Object.hash(runtimeType,segmentId,biome,fromMeters,toMeters);

@override
String toString() {
  return 'BiomeSpan(segmentId: $segmentId, biome: $biome, fromMeters: $fromMeters, toMeters: $toMeters)';
}


}

/// @nodoc
abstract mixin class $BiomeSpanCopyWith<$Res>  {
  factory $BiomeSpanCopyWith(BiomeSpan value, $Res Function(BiomeSpan) _then) = _$BiomeSpanCopyWithImpl;
@useResult
$Res call({
 String segmentId, String biome, int fromMeters, int toMeters
});




}
/// @nodoc
class _$BiomeSpanCopyWithImpl<$Res>
    implements $BiomeSpanCopyWith<$Res> {
  _$BiomeSpanCopyWithImpl(this._self, this._then);

  final BiomeSpan _self;
  final $Res Function(BiomeSpan) _then;

/// Create a copy of BiomeSpan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? segmentId = null,Object? biome = null,Object? fromMeters = null,Object? toMeters = null,}) {
  return _then(BiomeSpan(
segmentId: null == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String,biome: null == biome ? _self.biome : biome // ignore: cast_nullable_to_non_nullable
as String,fromMeters: null == fromMeters ? _self.fromMeters : fromMeters // ignore: cast_nullable_to_non_nullable
as int,toMeters: null == toMeters ? _self.toMeters : toMeters // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BiomeSpan].
extension BiomeSpanPatterns on BiomeSpan {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BiomeSpan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BiomeSpan() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BiomeSpan value)  $default,){
final _that = this;
switch (_that) {
case _BiomeSpan():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BiomeSpan value)?  $default,){
final _that = this;
switch (_that) {
case _BiomeSpan() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String segmentId,  String biome,  int fromMeters,  int toMeters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BiomeSpan() when $default != null:
return $default(_that.segmentId,_that.biome,_that.fromMeters,_that.toMeters);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String segmentId,  String biome,  int fromMeters,  int toMeters)  $default,) {final _that = this;
switch (_that) {
case _BiomeSpan():
return $default(_that.segmentId,_that.biome,_that.fromMeters,_that.toMeters);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String segmentId,  String biome,  int fromMeters,  int toMeters)?  $default,) {final _that = this;
switch (_that) {
case _BiomeSpan() when $default != null:
return $default(_that.segmentId,_that.biome,_that.fromMeters,_that.toMeters);case _:
  return null;

}
}

}

/// @nodoc


class _BiomeSpan implements BiomeSpan {
  const _BiomeSpan({required this.segmentId, required this.biome, required this.fromMeters, required this.toMeters});
  

@override final  String segmentId;
@override final  String biome;
@override final  int fromMeters;
@override final  int toMeters;

/// Create a copy of BiomeSpan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BiomeSpanCopyWith<_BiomeSpan> get copyWith => __$BiomeSpanCopyWithImpl<_BiomeSpan>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BiomeSpan&&(identical(other.segmentId, segmentId) || other.segmentId == segmentId)&&(identical(other.biome, biome) || other.biome == biome)&&(identical(other.fromMeters, fromMeters) || other.fromMeters == fromMeters)&&(identical(other.toMeters, toMeters) || other.toMeters == toMeters));
}


@override
int get hashCode => Object.hash(runtimeType,segmentId,biome,fromMeters,toMeters);

@override
String toString() {
  return 'BiomeSpan(segmentId: $segmentId, biome: $biome, fromMeters: $fromMeters, toMeters: $toMeters)';
}


}

/// @nodoc
abstract mixin class _$BiomeSpanCopyWith<$Res> implements $BiomeSpanCopyWith<$Res> {
  factory _$BiomeSpanCopyWith(_BiomeSpan value, $Res Function(_BiomeSpan) _then) = __$BiomeSpanCopyWithImpl;
@override @useResult
$Res call({
 String segmentId, String biome, int fromMeters, int toMeters
});




}
/// @nodoc
class __$BiomeSpanCopyWithImpl<$Res>
    implements _$BiomeSpanCopyWith<$Res> {
  __$BiomeSpanCopyWithImpl(this._self, this._then);

  final _BiomeSpan _self;
  final $Res Function(_BiomeSpan) _then;

/// Create a copy of BiomeSpan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? segmentId = null,Object? biome = null,Object? fromMeters = null,Object? toMeters = null,}) {
  return _then(_BiomeSpan(
segmentId: null == segmentId ? _self.segmentId : segmentId // ignore: cast_nullable_to_non_nullable
as String,biome: null == biome ? _self.biome : biome // ignore: cast_nullable_to_non_nullable
as String,fromMeters: null == fromMeters ? _self.fromMeters : fromMeters // ignore: cast_nullable_to_non_nullable
as int,toMeters: null == toMeters ? _self.toMeters : toMeters // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
