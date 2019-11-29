import 'dart:io' show Platform;
import 'package:device_info/device_info.dart';


class DeviceInfoService {
    final _deviceInfo = DeviceInfoPlugin();
    Map<String, dynamic> deviceInfo;

    DeviceInfoService() {
        _getDeviceInfo()
            .then((result) {
                deviceInfo = result;
                print(result);
            });
    }

    Future<Map<String, dynamic>> _getDeviceInfo() async {
        try {
            if (Platform.isAndroid) {
                final AndroidDeviceInfo device = await _deviceInfo.androidInfo;
                return {
                    'androidId': device.androidId,
                    'board': device.board,
                    'bootloader': device.bootloader,
                    'brand': device.brand,
                    'device': device.device,
                    'display': device.display,
                    'fingerprint': device.fingerprint,
                    'hardware': device.hardware,
                    'host': device.host,
                    'id': device.id,
                    'isPhysicalDevice': device.isPhysicalDevice,
                    'manufacturer': device.manufacturer,
                    'model': device.model,
                    'product': device.product,
                    'tags': device.tags,
                    'type': device.type,
                    'version': device.version.release,
                    'sdk': device.version.sdkInt,
                };
            } else if (Platform.isIOS) {
                final IosDeviceInfo device = await _deviceInfo.iosInfo;
                return {
                    'identifierForVendor': device.identifierForVendor,
                    'isPhysicalDevice': device.isPhysicalDevice,
                    'localizedModel': device.localizedModel,
                    'model': device.model,
                    'name': device.name,
                    'systemName': device.systemName,
                    'systemVersion': device.systemVersion,
                    'version': device.utsname.version,
                };
            } else {
                throw 'invalid device platform!';
            }
        } catch (err) {
            print('[CallFeedbackService][_getDeviceInfo] ERROR = $err');
            return Map<String, String>();
        }
    }
}
