// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'android_auto_wireless_network.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AndroidAutoWirelessNetwork {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AndroidAutoWirelessNetwork);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AndroidAutoWirelessNetwork()';
}


}

/// @nodoc
class $AndroidAutoWirelessNetworkCopyWith<$Res>  {
$AndroidAutoWirelessNetworkCopyWith(AndroidAutoWirelessNetwork _, $Res Function(AndroidAutoWirelessNetwork) __);
}


/// Adds pattern-matching-related methods to [AndroidAutoWirelessNetwork].
extension AndroidAutoWirelessNetworkPatterns on AndroidAutoWirelessNetwork {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AndroidAutoHotspotNetwork value)?  hotspot,TResult Function( AndroidAutoExistingNetwork value)?  existing,TResult Function( AndroidAutoNoNetwork value)?  none,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AndroidAutoHotspotNetwork() when hotspot != null:
return hotspot(_that);case AndroidAutoExistingNetwork() when existing != null:
return existing(_that);case AndroidAutoNoNetwork() when none != null:
return none(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AndroidAutoHotspotNetwork value)  hotspot,required TResult Function( AndroidAutoExistingNetwork value)  existing,required TResult Function( AndroidAutoNoNetwork value)  none,}){
final _that = this;
switch (_that) {
case AndroidAutoHotspotNetwork():
return hotspot(_that);case AndroidAutoExistingNetwork():
return existing(_that);case AndroidAutoNoNetwork():
return none(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AndroidAutoHotspotNetwork value)?  hotspot,TResult? Function( AndroidAutoExistingNetwork value)?  existing,TResult? Function( AndroidAutoNoNetwork value)?  none,}){
final _that = this;
switch (_that) {
case AndroidAutoHotspotNetwork() when hotspot != null:
return hotspot(_that);case AndroidAutoExistingNetwork() when existing != null:
return existing(_that);case AndroidAutoNoNetwork() when none != null:
return none(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? name)?  hotspot,TResult Function( String passphrase,  String name,  String interfaceName)?  existing,TResult Function()?  none,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AndroidAutoHotspotNetwork() when hotspot != null:
return hotspot(_that.name);case AndroidAutoExistingNetwork() when existing != null:
return existing(_that.passphrase,_that.name,_that.interfaceName);case AndroidAutoNoNetwork() when none != null:
return none();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? name)  hotspot,required TResult Function( String passphrase,  String name,  String interfaceName)  existing,required TResult Function()  none,}) {final _that = this;
switch (_that) {
case AndroidAutoHotspotNetwork():
return hotspot(_that.name);case AndroidAutoExistingNetwork():
return existing(_that.passphrase,_that.name,_that.interfaceName);case AndroidAutoNoNetwork():
return none();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? name)?  hotspot,TResult? Function( String passphrase,  String name,  String interfaceName)?  existing,TResult? Function()?  none,}) {final _that = this;
switch (_that) {
case AndroidAutoHotspotNetwork() when hotspot != null:
return hotspot(_that.name);case AndroidAutoExistingNetwork() when existing != null:
return existing(_that.passphrase,_that.name,_that.interfaceName);case AndroidAutoNoNetwork() when none != null:
return none();case _:
  return null;

}
}

}

/// @nodoc


class AndroidAutoHotspotNetwork implements AndroidAutoWirelessNetwork {
  const AndroidAutoHotspotNetwork({this.name});
  

/// The network's name, what anyone nearby sees in their Wi-Fi list. Leave
/// it `null` to use the car's name from `AboutConfig.deviceName`.
 final  String? name;

/// Create a copy of AndroidAutoWirelessNetwork
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AndroidAutoHotspotNetworkCopyWith<AndroidAutoHotspotNetwork> get copyWith => _$AndroidAutoHotspotNetworkCopyWithImpl<AndroidAutoHotspotNetwork>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AndroidAutoHotspotNetwork&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'AndroidAutoWirelessNetwork.hotspot(name: $name)';
}


}

/// @nodoc
abstract mixin class $AndroidAutoHotspotNetworkCopyWith<$Res> implements $AndroidAutoWirelessNetworkCopyWith<$Res> {
  factory $AndroidAutoHotspotNetworkCopyWith(AndroidAutoHotspotNetwork value, $Res Function(AndroidAutoHotspotNetwork) _then) = _$AndroidAutoHotspotNetworkCopyWithImpl;
@useResult
$Res call({
 String? name
});




}
/// @nodoc
class _$AndroidAutoHotspotNetworkCopyWithImpl<$Res>
    implements $AndroidAutoHotspotNetworkCopyWith<$Res> {
  _$AndroidAutoHotspotNetworkCopyWithImpl(this._self, this._then);

  final AndroidAutoHotspotNetwork _self;
  final $Res Function(AndroidAutoHotspotNetwork) _then;

/// Create a copy of AndroidAutoWirelessNetwork
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = freezed,}) {
  return _then(AndroidAutoHotspotNetwork(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class AndroidAutoExistingNetwork implements AndroidAutoWirelessNetwork {
  const AndroidAutoExistingNetwork({required this.passphrase, this.name = '', this.interfaceName = ''});
  

 final  String passphrase;
/// The network's name. Leave it empty to read it off the car's Wi-Fi,
/// which is right whenever the car is on the network itself.
@JsonKey() final  String name;
/// Which network interface to describe, `wlan0` and the like. Empty picks
/// the first one with an address.
@JsonKey() final  String interfaceName;

/// Create a copy of AndroidAutoWirelessNetwork
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AndroidAutoExistingNetworkCopyWith<AndroidAutoExistingNetwork> get copyWith => _$AndroidAutoExistingNetworkCopyWithImpl<AndroidAutoExistingNetwork>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AndroidAutoExistingNetwork&&(identical(other.passphrase, passphrase) || other.passphrase == passphrase)&&(identical(other.name, name) || other.name == name)&&(identical(other.interfaceName, interfaceName) || other.interfaceName == interfaceName));
}


@override
int get hashCode => Object.hash(runtimeType,passphrase,name,interfaceName);

@override
String toString() {
  return 'AndroidAutoWirelessNetwork.existing(passphrase: $passphrase, name: $name, interfaceName: $interfaceName)';
}


}

/// @nodoc
abstract mixin class $AndroidAutoExistingNetworkCopyWith<$Res> implements $AndroidAutoWirelessNetworkCopyWith<$Res> {
  factory $AndroidAutoExistingNetworkCopyWith(AndroidAutoExistingNetwork value, $Res Function(AndroidAutoExistingNetwork) _then) = _$AndroidAutoExistingNetworkCopyWithImpl;
@useResult
$Res call({
 String passphrase, String name, String interfaceName
});




}
/// @nodoc
class _$AndroidAutoExistingNetworkCopyWithImpl<$Res>
    implements $AndroidAutoExistingNetworkCopyWith<$Res> {
  _$AndroidAutoExistingNetworkCopyWithImpl(this._self, this._then);

  final AndroidAutoExistingNetwork _self;
  final $Res Function(AndroidAutoExistingNetwork) _then;

/// Create a copy of AndroidAutoWirelessNetwork
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? passphrase = null,Object? name = null,Object? interfaceName = null,}) {
  return _then(AndroidAutoExistingNetwork(
passphrase: null == passphrase ? _self.passphrase : passphrase // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,interfaceName: null == interfaceName ? _self.interfaceName : interfaceName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AndroidAutoNoNetwork implements AndroidAutoWirelessNetwork {
  const AndroidAutoNoNetwork();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AndroidAutoNoNetwork);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AndroidAutoWirelessNetwork.none()';
}


}




// dart format on
