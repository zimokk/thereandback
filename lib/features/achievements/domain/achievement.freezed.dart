// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'achievement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AchievementDef {

 String get id;/// L10n key for the title — achievement copy is UI text (§11), not
/// narrative content, so it lives in the ARB files like any other label.
 String get titleKey; AchievementKind get kind; int get thresholdMeters;/// `null` — a generic milestone that applies to whichever quest is
/// active (e.g. "First Steps"); a catalog id — this entry only makes
/// sense for that one quest (its `landmarkReached` entries above all,
/// since a threshold there is literally a specific quest's own
/// landmark meters, but also a `distanceReached` one picked to land on
/// a specific quest's own milestone, like "halfway through *this*
/// route"). Added when the catalog grew a second quest (§14,
/// 2026-09-05) — before that every entry's threshold happened to
/// exceed any other quest's length, so the absence of scoping never
/// showed. [achievementsForJourney] is the one place that reads this.
 String? get journeyId;
/// Create a copy of AchievementDef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AchievementDefCopyWith<AchievementDef> get copyWith => _$AchievementDefCopyWithImpl<AchievementDef>(this as AchievementDef, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AchievementDef&&(identical(other.id, id) || other.id == id)&&(identical(other.titleKey, titleKey) || other.titleKey == titleKey)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.thresholdMeters, thresholdMeters) || other.thresholdMeters == thresholdMeters)&&(identical(other.journeyId, journeyId) || other.journeyId == journeyId));
}


@override
int get hashCode => Object.hash(runtimeType,id,titleKey,kind,thresholdMeters,journeyId);

@override
String toString() {
  return 'AchievementDef(id: $id, titleKey: $titleKey, kind: $kind, thresholdMeters: $thresholdMeters, journeyId: $journeyId)';
}


}

/// @nodoc
abstract mixin class $AchievementDefCopyWith<$Res>  {
  factory $AchievementDefCopyWith(AchievementDef value, $Res Function(AchievementDef) _then) = _$AchievementDefCopyWithImpl;
@useResult
$Res call({
 String id, String titleKey, AchievementKind kind, int thresholdMeters, String? journeyId
});




}
/// @nodoc
class _$AchievementDefCopyWithImpl<$Res>
    implements $AchievementDefCopyWith<$Res> {
  _$AchievementDefCopyWithImpl(this._self, this._then);

  final AchievementDef _self;
  final $Res Function(AchievementDef) _then;

/// Create a copy of AchievementDef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? titleKey = null,Object? kind = null,Object? thresholdMeters = null,Object? journeyId = freezed,}) {
  return _then(AchievementDef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,titleKey: null == titleKey ? _self.titleKey : titleKey // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AchievementKind,thresholdMeters: null == thresholdMeters ? _self.thresholdMeters : thresholdMeters // ignore: cast_nullable_to_non_nullable
as int,journeyId: freezed == journeyId ? _self.journeyId : journeyId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AchievementDef].
extension AchievementDefPatterns on AchievementDef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AchievementDef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AchievementDef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AchievementDef value)  $default,){
final _that = this;
switch (_that) {
case _AchievementDef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AchievementDef value)?  $default,){
final _that = this;
switch (_that) {
case _AchievementDef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String titleKey,  AchievementKind kind,  int thresholdMeters,  String? journeyId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AchievementDef() when $default != null:
return $default(_that.id,_that.titleKey,_that.kind,_that.thresholdMeters,_that.journeyId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String titleKey,  AchievementKind kind,  int thresholdMeters,  String? journeyId)  $default,) {final _that = this;
switch (_that) {
case _AchievementDef():
return $default(_that.id,_that.titleKey,_that.kind,_that.thresholdMeters,_that.journeyId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String titleKey,  AchievementKind kind,  int thresholdMeters,  String? journeyId)?  $default,) {final _that = this;
switch (_that) {
case _AchievementDef() when $default != null:
return $default(_that.id,_that.titleKey,_that.kind,_that.thresholdMeters,_that.journeyId);case _:
  return null;

}
}

}

/// @nodoc


class _AchievementDef implements AchievementDef {
  const _AchievementDef({required this.id, required this.titleKey, required this.kind, required this.thresholdMeters, this.journeyId});
  

@override final  String id;
/// L10n key for the title — achievement copy is UI text (§11), not
/// narrative content, so it lives in the ARB files like any other label.
@override final  String titleKey;
@override final  AchievementKind kind;
@override final  int thresholdMeters;
/// `null` — a generic milestone that applies to whichever quest is
/// active (e.g. "First Steps"); a catalog id — this entry only makes
/// sense for that one quest (its `landmarkReached` entries above all,
/// since a threshold there is literally a specific quest's own
/// landmark meters, but also a `distanceReached` one picked to land on
/// a specific quest's own milestone, like "halfway through *this*
/// route"). Added when the catalog grew a second quest (§14,
/// 2026-09-05) — before that every entry's threshold happened to
/// exceed any other quest's length, so the absence of scoping never
/// showed. [achievementsForJourney] is the one place that reads this.
@override final  String? journeyId;

/// Create a copy of AchievementDef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AchievementDefCopyWith<_AchievementDef> get copyWith => __$AchievementDefCopyWithImpl<_AchievementDef>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AchievementDef&&(identical(other.id, id) || other.id == id)&&(identical(other.titleKey, titleKey) || other.titleKey == titleKey)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.thresholdMeters, thresholdMeters) || other.thresholdMeters == thresholdMeters)&&(identical(other.journeyId, journeyId) || other.journeyId == journeyId));
}


@override
int get hashCode => Object.hash(runtimeType,id,titleKey,kind,thresholdMeters,journeyId);

@override
String toString() {
  return 'AchievementDef(id: $id, titleKey: $titleKey, kind: $kind, thresholdMeters: $thresholdMeters, journeyId: $journeyId)';
}


}

/// @nodoc
abstract mixin class _$AchievementDefCopyWith<$Res> implements $AchievementDefCopyWith<$Res> {
  factory _$AchievementDefCopyWith(_AchievementDef value, $Res Function(_AchievementDef) _then) = __$AchievementDefCopyWithImpl;
@override @useResult
$Res call({
 String id, String titleKey, AchievementKind kind, int thresholdMeters, String? journeyId
});




}
/// @nodoc
class __$AchievementDefCopyWithImpl<$Res>
    implements _$AchievementDefCopyWith<$Res> {
  __$AchievementDefCopyWithImpl(this._self, this._then);

  final _AchievementDef _self;
  final $Res Function(_AchievementDef) _then;

/// Create a copy of AchievementDef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? titleKey = null,Object? kind = null,Object? thresholdMeters = null,Object? journeyId = freezed,}) {
  return _then(_AchievementDef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,titleKey: null == titleKey ? _self.titleKey : titleKey // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AchievementKind,thresholdMeters: null == thresholdMeters ? _self.thresholdMeters : thresholdMeters // ignore: cast_nullable_to_non_nullable
as int,journeyId: freezed == journeyId ? _self.journeyId : journeyId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AchievementState {

 AchievementDef get def; bool get unlocked;/// Meters still needed to unlock; `0` once [unlocked] is true.
 int get remainingMeters;
/// Create a copy of AchievementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AchievementStateCopyWith<AchievementState> get copyWith => _$AchievementStateCopyWithImpl<AchievementState>(this as AchievementState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AchievementState&&(identical(other.def, def) || other.def == def)&&(identical(other.unlocked, unlocked) || other.unlocked == unlocked)&&(identical(other.remainingMeters, remainingMeters) || other.remainingMeters == remainingMeters));
}


@override
int get hashCode => Object.hash(runtimeType,def,unlocked,remainingMeters);

@override
String toString() {
  return 'AchievementState(def: $def, unlocked: $unlocked, remainingMeters: $remainingMeters)';
}


}

/// @nodoc
abstract mixin class $AchievementStateCopyWith<$Res>  {
  factory $AchievementStateCopyWith(AchievementState value, $Res Function(AchievementState) _then) = _$AchievementStateCopyWithImpl;
@useResult
$Res call({
 AchievementDef def, bool unlocked, int remainingMeters
});


$AchievementDefCopyWith<$Res> get def;

}
/// @nodoc
class _$AchievementStateCopyWithImpl<$Res>
    implements $AchievementStateCopyWith<$Res> {
  _$AchievementStateCopyWithImpl(this._self, this._then);

  final AchievementState _self;
  final $Res Function(AchievementState) _then;

/// Create a copy of AchievementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? def = null,Object? unlocked = null,Object? remainingMeters = null,}) {
  return _then(AchievementState(
def: null == def ? _self.def : def // ignore: cast_nullable_to_non_nullable
as AchievementDef,unlocked: null == unlocked ? _self.unlocked : unlocked // ignore: cast_nullable_to_non_nullable
as bool,remainingMeters: null == remainingMeters ? _self.remainingMeters : remainingMeters // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of AchievementState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AchievementDefCopyWith<$Res> get def {
  
  return $AchievementDefCopyWith<$Res>(_self.def, (value) {
    return _then(_self.copyWith(def: value));
  });
}
}


/// Adds pattern-matching-related methods to [AchievementState].
extension AchievementStatePatterns on AchievementState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AchievementState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AchievementState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AchievementState value)  $default,){
final _that = this;
switch (_that) {
case _AchievementState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AchievementState value)?  $default,){
final _that = this;
switch (_that) {
case _AchievementState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AchievementDef def,  bool unlocked,  int remainingMeters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AchievementState() when $default != null:
return $default(_that.def,_that.unlocked,_that.remainingMeters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AchievementDef def,  bool unlocked,  int remainingMeters)  $default,) {final _that = this;
switch (_that) {
case _AchievementState():
return $default(_that.def,_that.unlocked,_that.remainingMeters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AchievementDef def,  bool unlocked,  int remainingMeters)?  $default,) {final _that = this;
switch (_that) {
case _AchievementState() when $default != null:
return $default(_that.def,_that.unlocked,_that.remainingMeters);case _:
  return null;

}
}

}

/// @nodoc


class _AchievementState implements AchievementState {
  const _AchievementState({required this.def, required this.unlocked, required this.remainingMeters});
  

@override final  AchievementDef def;
@override final  bool unlocked;
/// Meters still needed to unlock; `0` once [unlocked] is true.
@override final  int remainingMeters;

/// Create a copy of AchievementState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AchievementStateCopyWith<_AchievementState> get copyWith => __$AchievementStateCopyWithImpl<_AchievementState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AchievementState&&(identical(other.def, def) || other.def == def)&&(identical(other.unlocked, unlocked) || other.unlocked == unlocked)&&(identical(other.remainingMeters, remainingMeters) || other.remainingMeters == remainingMeters));
}


@override
int get hashCode => Object.hash(runtimeType,def,unlocked,remainingMeters);

@override
String toString() {
  return 'AchievementState(def: $def, unlocked: $unlocked, remainingMeters: $remainingMeters)';
}


}

/// @nodoc
abstract mixin class _$AchievementStateCopyWith<$Res> implements $AchievementStateCopyWith<$Res> {
  factory _$AchievementStateCopyWith(_AchievementState value, $Res Function(_AchievementState) _then) = __$AchievementStateCopyWithImpl;
@override @useResult
$Res call({
 AchievementDef def, bool unlocked, int remainingMeters
});


@override $AchievementDefCopyWith<$Res> get def;

}
/// @nodoc
class __$AchievementStateCopyWithImpl<$Res>
    implements _$AchievementStateCopyWith<$Res> {
  __$AchievementStateCopyWithImpl(this._self, this._then);

  final _AchievementState _self;
  final $Res Function(_AchievementState) _then;

/// Create a copy of AchievementState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? def = null,Object? unlocked = null,Object? remainingMeters = null,}) {
  return _then(_AchievementState(
def: null == def ? _self.def : def // ignore: cast_nullable_to_non_nullable
as AchievementDef,unlocked: null == unlocked ? _self.unlocked : unlocked // ignore: cast_nullable_to_non_nullable
as bool,remainingMeters: null == remainingMeters ? _self.remainingMeters : remainingMeters // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of AchievementState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AchievementDefCopyWith<$Res> get def {
  
  return $AchievementDefCopyWith<$Res>(_self.def, (value) {
    return _then(_self.copyWith(def: value));
  });
}
}

// dart format on
