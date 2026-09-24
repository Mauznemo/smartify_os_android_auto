// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'android_auto_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AndroidAutoState {

 AndroidAutoPhase get phase;/// How the phone is connected. Only set while [phase] is
/// [AndroidAutoPhase.connected].
 AndroidAutoConnection? get connection;/// The last thing that went wrong, in words, or `null`. Cleared when the
/// next session starts. Worth showing wherever the driver would otherwise
/// wonder why nothing is happening.
 String? get problem;/// Whether Android Auto starts by itself when a phone is plugged in, or a
/// phone it knows connects over Bluetooth.
 bool get autostart;/// Whether the driver allows Android Auto without a cable. Only matters
/// when [wirelessAvailable].
 bool get wireless;/// Whether this car can do Android Auto without a cable at all, that is
/// whether it was set up with a Wi-Fi network for the phone.
 bool get wirelessAvailable;/// The name of the Wi-Fi hotspot the car brings up for the phone, or
/// `null` when it does not bring one up.
 String? get hotspotName;/// The Bluetooth addresses of the phones that start Android Auto on their
/// own when they connect: every phone that has used it here without a
/// cable.
 Set<String> get wirelessPhones;
/// Create a copy of AndroidAutoState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AndroidAutoStateCopyWith<AndroidAutoState> get copyWith => _$AndroidAutoStateCopyWithImpl<AndroidAutoState>(this as AndroidAutoState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AndroidAutoState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.connection, connection) || other.connection == connection)&&(identical(other.problem, problem) || other.problem == problem)&&(identical(other.autostart, autostart) || other.autostart == autostart)&&(identical(other.wireless, wireless) || other.wireless == wireless)&&(identical(other.wirelessAvailable, wirelessAvailable) || other.wirelessAvailable == wirelessAvailable)&&(identical(other.hotspotName, hotspotName) || other.hotspotName == hotspotName)&&const DeepCollectionEquality().equals(other.wirelessPhones, wirelessPhones));
}


@override
int get hashCode => Object.hash(runtimeType,phase,connection,problem,autostart,wireless,wirelessAvailable,hotspotName,const DeepCollectionEquality().hash(wirelessPhones));

@override
String toString() {
  return 'AndroidAutoState(phase: $phase, connection: $connection, problem: $problem, autostart: $autostart, wireless: $wireless, wirelessAvailable: $wirelessAvailable, hotspotName: $hotspotName, wirelessPhones: $wirelessPhones)';
}


}

/// @nodoc
abstract mixin class $AndroidAutoStateCopyWith<$Res>  {
  factory $AndroidAutoStateCopyWith(AndroidAutoState value, $Res Function(AndroidAutoState) _then) = _$AndroidAutoStateCopyWithImpl;
@useResult
$Res call({
 AndroidAutoPhase phase, AndroidAutoConnection? connection, String? problem, bool autostart, bool wireless, bool wirelessAvailable, String? hotspotName, Set<String> wirelessPhones
});




}
/// @nodoc
class _$AndroidAutoStateCopyWithImpl<$Res>
    implements $AndroidAutoStateCopyWith<$Res> {
  _$AndroidAutoStateCopyWithImpl(this._self, this._then);

  final AndroidAutoState _self;
  final $Res Function(AndroidAutoState) _then;

/// Create a copy of AndroidAutoState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? connection = freezed,Object? problem = freezed,Object? autostart = null,Object? wireless = null,Object? wirelessAvailable = null,Object? hotspotName = freezed,Object? wirelessPhones = null,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as AndroidAutoPhase,connection: freezed == connection ? _self.connection : connection // ignore: cast_nullable_to_non_nullable
as AndroidAutoConnection?,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as String?,autostart: null == autostart ? _self.autostart : autostart // ignore: cast_nullable_to_non_nullable
as bool,wireless: null == wireless ? _self.wireless : wireless // ignore: cast_nullable_to_non_nullable
as bool,wirelessAvailable: null == wirelessAvailable ? _self.wirelessAvailable : wirelessAvailable // ignore: cast_nullable_to_non_nullable
as bool,hotspotName: freezed == hotspotName ? _self.hotspotName : hotspotName // ignore: cast_nullable_to_non_nullable
as String?,wirelessPhones: null == wirelessPhones ? _self.wirelessPhones : wirelessPhones // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AndroidAutoState].
extension AndroidAutoStatePatterns on AndroidAutoState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AndroidAutoState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AndroidAutoState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AndroidAutoState value)  $default,){
final _that = this;
switch (_that) {
case _AndroidAutoState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AndroidAutoState value)?  $default,){
final _that = this;
switch (_that) {
case _AndroidAutoState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AndroidAutoPhase phase,  AndroidAutoConnection? connection,  String? problem,  bool autostart,  bool wireless,  bool wirelessAvailable,  String? hotspotName,  Set<String> wirelessPhones)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AndroidAutoState() when $default != null:
return $default(_that.phase,_that.connection,_that.problem,_that.autostart,_that.wireless,_that.wirelessAvailable,_that.hotspotName,_that.wirelessPhones);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AndroidAutoPhase phase,  AndroidAutoConnection? connection,  String? problem,  bool autostart,  bool wireless,  bool wirelessAvailable,  String? hotspotName,  Set<String> wirelessPhones)  $default,) {final _that = this;
switch (_that) {
case _AndroidAutoState():
return $default(_that.phase,_that.connection,_that.problem,_that.autostart,_that.wireless,_that.wirelessAvailable,_that.hotspotName,_that.wirelessPhones);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AndroidAutoPhase phase,  AndroidAutoConnection? connection,  String? problem,  bool autostart,  bool wireless,  bool wirelessAvailable,  String? hotspotName,  Set<String> wirelessPhones)?  $default,) {final _that = this;
switch (_that) {
case _AndroidAutoState() when $default != null:
return $default(_that.phase,_that.connection,_that.problem,_that.autostart,_that.wireless,_that.wirelessAvailable,_that.hotspotName,_that.wirelessPhones);case _:
  return null;

}
}

}

/// @nodoc


class _AndroidAutoState extends AndroidAutoState {
  const _AndroidAutoState({this.phase = AndroidAutoPhase.stopped, this.connection, this.problem, this.autostart = false, this.wireless = true, this.wirelessAvailable = false, this.hotspotName, final  Set<String> wirelessPhones = const <String>{}}): _wirelessPhones = wirelessPhones,super._();
  

@override@JsonKey() final  AndroidAutoPhase phase;
/// How the phone is connected. Only set while [phase] is
/// [AndroidAutoPhase.connected].
@override final  AndroidAutoConnection? connection;
/// The last thing that went wrong, in words, or `null`. Cleared when the
/// next session starts. Worth showing wherever the driver would otherwise
/// wonder why nothing is happening.
@override final  String? problem;
/// Whether Android Auto starts by itself when a phone is plugged in, or a
/// phone it knows connects over Bluetooth.
@override@JsonKey() final  bool autostart;
/// Whether the driver allows Android Auto without a cable. Only matters
/// when [wirelessAvailable].
@override@JsonKey() final  bool wireless;
/// Whether this car can do Android Auto without a cable at all, that is
/// whether it was set up with a Wi-Fi network for the phone.
@override@JsonKey() final  bool wirelessAvailable;
/// The name of the Wi-Fi hotspot the car brings up for the phone, or
/// `null` when it does not bring one up.
@override final  String? hotspotName;
/// The Bluetooth addresses of the phones that start Android Auto on their
/// own when they connect: every phone that has used it here without a
/// cable.
 final  Set<String> _wirelessPhones;
/// The Bluetooth addresses of the phones that start Android Auto on their
/// own when they connect: every phone that has used it here without a
/// cable.
@override@JsonKey() Set<String> get wirelessPhones {
  if (_wirelessPhones is EqualUnmodifiableSetView) return _wirelessPhones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_wirelessPhones);
}


/// Create a copy of AndroidAutoState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AndroidAutoStateCopyWith<_AndroidAutoState> get copyWith => __$AndroidAutoStateCopyWithImpl<_AndroidAutoState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AndroidAutoState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.connection, connection) || other.connection == connection)&&(identical(other.problem, problem) || other.problem == problem)&&(identical(other.autostart, autostart) || other.autostart == autostart)&&(identical(other.wireless, wireless) || other.wireless == wireless)&&(identical(other.wirelessAvailable, wirelessAvailable) || other.wirelessAvailable == wirelessAvailable)&&(identical(other.hotspotName, hotspotName) || other.hotspotName == hotspotName)&&const DeepCollectionEquality().equals(other._wirelessPhones, _wirelessPhones));
}


@override
int get hashCode => Object.hash(runtimeType,phase,connection,problem,autostart,wireless,wirelessAvailable,hotspotName,const DeepCollectionEquality().hash(_wirelessPhones));

@override
String toString() {
  return 'AndroidAutoState(phase: $phase, connection: $connection, problem: $problem, autostart: $autostart, wireless: $wireless, wirelessAvailable: $wirelessAvailable, hotspotName: $hotspotName, wirelessPhones: $wirelessPhones)';
}


}

/// @nodoc
abstract mixin class _$AndroidAutoStateCopyWith<$Res> implements $AndroidAutoStateCopyWith<$Res> {
  factory _$AndroidAutoStateCopyWith(_AndroidAutoState value, $Res Function(_AndroidAutoState) _then) = __$AndroidAutoStateCopyWithImpl;
@override @useResult
$Res call({
 AndroidAutoPhase phase, AndroidAutoConnection? connection, String? problem, bool autostart, bool wireless, bool wirelessAvailable, String? hotspotName, Set<String> wirelessPhones
});




}
/// @nodoc
class __$AndroidAutoStateCopyWithImpl<$Res>
    implements _$AndroidAutoStateCopyWith<$Res> {
  __$AndroidAutoStateCopyWithImpl(this._self, this._then);

  final _AndroidAutoState _self;
  final $Res Function(_AndroidAutoState) _then;

/// Create a copy of AndroidAutoState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? connection = freezed,Object? problem = freezed,Object? autostart = null,Object? wireless = null,Object? wirelessAvailable = null,Object? hotspotName = freezed,Object? wirelessPhones = null,}) {
  return _then(_AndroidAutoState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as AndroidAutoPhase,connection: freezed == connection ? _self.connection : connection // ignore: cast_nullable_to_non_nullable
as AndroidAutoConnection?,problem: freezed == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as String?,autostart: null == autostart ? _self.autostart : autostart // ignore: cast_nullable_to_non_nullable
as bool,wireless: null == wireless ? _self.wireless : wireless // ignore: cast_nullable_to_non_nullable
as bool,wirelessAvailable: null == wirelessAvailable ? _self.wirelessAvailable : wirelessAvailable // ignore: cast_nullable_to_non_nullable
as bool,hotspotName: freezed == hotspotName ? _self.hotspotName : hotspotName // ignore: cast_nullable_to_non_nullable
as String?,wirelessPhones: null == wirelessPhones ? _self._wirelessPhones : wirelessPhones // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
