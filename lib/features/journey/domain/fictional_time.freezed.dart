// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fictional_time.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JourneySegmentTiming {

 String get id; int get fromMeters; int get toMeters; double get departureHour; double get durationDays;
/// Create a copy of JourneySegmentTiming
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JourneySegmentTimingCopyWith<JourneySegmentTiming> get copyWith => _$JourneySegmentTimingCopyWithImpl<JourneySegmentTiming>(this as JourneySegmentTiming, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JourneySegmentTiming&&(identical(other.id, id) || other.id == id)&&(identical(other.fromMeters, fromMeters) || other.fromMeters == fromMeters)&&(identical(other.toMeters, toMeters) || other.toMeters == toMeters)&&(identical(other.departureHour, departureHour) || other.departureHour == departureHour)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays));
}


@override
int get hashCode => Object.hash(runtimeType,id,fromMeters,toMeters,departureHour,durationDays);

@override
String toString() {
  return 'JourneySegmentTiming(id: $id, fromMeters: $fromMeters, toMeters: $toMeters, departureHour: $departureHour, durationDays: $durationDays)';
}


}

/// @nodoc
abstract mixin class $JourneySegmentTimingCopyWith<$Res>  {
  factory $JourneySegmentTimingCopyWith(JourneySegmentTiming value, $Res Function(JourneySegmentTiming) _then) = _$JourneySegmentTimingCopyWithImpl;
@useResult
$Res call({
 String id, int fromMeters, int toMeters, double departureHour, double durationDays
});




}
/// @nodoc
class _$JourneySegmentTimingCopyWithImpl<$Res>
    implements $JourneySegmentTimingCopyWith<$Res> {
  _$JourneySegmentTimingCopyWithImpl(this._self, this._then);

  final JourneySegmentTiming _self;
  final $Res Function(JourneySegmentTiming) _then;

/// Create a copy of JourneySegmentTiming
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fromMeters = null,Object? toMeters = null,Object? departureHour = null,Object? durationDays = null,}) {
  return _then(JourneySegmentTiming(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromMeters: null == fromMeters ? _self.fromMeters : fromMeters // ignore: cast_nullable_to_non_nullable
as int,toMeters: null == toMeters ? _self.toMeters : toMeters // ignore: cast_nullable_to_non_nullable
as int,departureHour: null == departureHour ? _self.departureHour : departureHour // ignore: cast_nullable_to_non_nullable
as double,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [JourneySegmentTiming].
extension JourneySegmentTimingPatterns on JourneySegmentTiming {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JourneySegmentTiming value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JourneySegmentTiming() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JourneySegmentTiming value)  $default,){
final _that = this;
switch (_that) {
case _JourneySegmentTiming():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JourneySegmentTiming value)?  $default,){
final _that = this;
switch (_that) {
case _JourneySegmentTiming() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int fromMeters,  int toMeters,  double departureHour,  double durationDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JourneySegmentTiming() when $default != null:
return $default(_that.id,_that.fromMeters,_that.toMeters,_that.departureHour,_that.durationDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int fromMeters,  int toMeters,  double departureHour,  double durationDays)  $default,) {final _that = this;
switch (_that) {
case _JourneySegmentTiming():
return $default(_that.id,_that.fromMeters,_that.toMeters,_that.departureHour,_that.durationDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int fromMeters,  int toMeters,  double departureHour,  double durationDays)?  $default,) {final _that = this;
switch (_that) {
case _JourneySegmentTiming() when $default != null:
return $default(_that.id,_that.fromMeters,_that.toMeters,_that.departureHour,_that.durationDays);case _:
  return null;

}
}

}

/// @nodoc


class _JourneySegmentTiming implements JourneySegmentTiming {
  const _JourneySegmentTiming({required this.id, required this.fromMeters, required this.toMeters, required this.departureHour, required this.durationDays});


@override final  String id;
@override final  int fromMeters;
@override final  int toMeters;
@override final  double departureHour;
@override final  double durationDays;

/// Create a copy of JourneySegmentTiming
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JourneySegmentTimingCopyWith<_JourneySegmentTiming> get copyWith => __$JourneySegmentTimingCopyWithImpl<_JourneySegmentTiming>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JourneySegmentTiming&&(identical(other.id, id) || other.id == id)&&(identical(other.fromMeters, fromMeters) || other.fromMeters == fromMeters)&&(identical(other.toMeters, toMeters) || other.toMeters == toMeters)&&(identical(other.departureHour, departureHour) || other.departureHour == departureHour)&&(identical(other.durationDays, durationDays) || other.durationDays == durationDays));
}


@override
int get hashCode => Object.hash(runtimeType,id,fromMeters,toMeters,departureHour,durationDays);

@override
String toString() {
  return 'JourneySegmentTiming(id: $id, fromMeters: $fromMeters, toMeters: $toMeters, departureHour: $departureHour, durationDays: $durationDays)';
}


}

/// @nodoc
abstract mixin class _$JourneySegmentTimingCopyWith<$Res> implements $JourneySegmentTimingCopyWith<$Res> {
  factory _$JourneySegmentTimingCopyWith(_JourneySegmentTiming value, $Res Function(_JourneySegmentTiming) _then) = __$JourneySegmentTimingCopyWithImpl;
@override @useResult
$Res call({
 String id, int fromMeters, int toMeters, double departureHour, double durationDays
});




}
/// @nodoc
class __$JourneySegmentTimingCopyWithImpl<$Res>
    implements _$JourneySegmentTimingCopyWith<$Res> {
  __$JourneySegmentTimingCopyWithImpl(this._self, this._then);

  final _JourneySegmentTiming _self;
  final $Res Function(_JourneySegmentTiming) _then;

/// Create a copy of JourneySegmentTiming
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fromMeters = null,Object? toMeters = null,Object? departureHour = null,Object? durationDays = null,}) {
  return _then(_JourneySegmentTiming(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fromMeters: null == fromMeters ? _self.fromMeters : fromMeters // ignore: cast_nullable_to_non_nullable
as int,toMeters: null == toMeters ? _self.toMeters : toMeters // ignore: cast_nullable_to_non_nullable
as int,departureHour: null == departureHour ? _self.departureHour : departureHour // ignore: cast_nullable_to_non_nullable
as double,durationDays: null == durationDays ? _self.durationDays : durationDays // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
