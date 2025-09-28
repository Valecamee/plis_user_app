import 'package:flutter/material.dart';
import '../../widgets/registration/base_registration.dart';
import '../../widgets/registration/permission_item.dart';
import 'package:permission_handler/permission_handler.dart';

/// Pantalla que solicita los permisos necesarios para el funcionamiento de la app.
/// Adaptada específicamente para usuarios pasajeros.
class PermissionsScreen extends StatefulWidget {
  final VoidCallback onNext;

  const PermissionsScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  List<bool> permissionsGranted = [false, false, false];

  final List<Map<String, dynamic>> permissions = [
    {
      'icon': Image.asset(
        'assets/icons/map-pin.png',
        fit: BoxFit.contain,
        width: 42,
        height: 42,
      ),
      'text': 'Permiso de ubicación',
      'subtext': 'Necesitamos acceder a tu ubicación para encontrar viajes cercanos y calcular rutas óptimas.'
    },
    {
      'icon': Image.asset(
        'assets/icons/device-mobile.png',
        fit: BoxFit.contain,
        width: 42,
        height: 42,
      ),
      'text': 'Permiso de teléfono',
      'subtext': 'Utilizamos tu número de teléfono para validar tu cuenta y facilitar la comunicación con el conductor.'
    },
    {
      'icon': Image.asset(
        'assets/icons/bell.png',
        fit: BoxFit.contain,
        width: 42,
        height: 42,
      ),
      'text': 'Permiso de notificaciones',
      'subtext': 'Con este permiso podemos enviarte alertas en tiempo real sobre el estado de tus viajes y reservas.'
    },
  ];

  Future<void> solicitarPermiso(int index) async {
    bool concedido = false;

    if (index == 0) {
      // Permiso de ubicación
      var status = await Permission.location.request();
      concedido = status.isGranted;
    } else if (index == 1) {
      // Permiso de teléfono
      var status = await Permission.phone.request();
      concedido = status.isGranted;
    } else if (index == 2) {
      // Permiso de notificaciones
      var status = await Permission.notification.request();
      concedido = status.isGranted;
    }

    setState(() {
      permissionsGranted[index] = concedido;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseRegistrationScreen(
      title: 'Permisos Necesarios',
      subtitle: 'Para brindarte la mejor experiencia, necesitamos los siguientes permisos',
      onNext: widget.onNext,
      buttonEnabled: permissionsGranted.every((p) => p),
      child: Column(
        children: [
          ...List.generate(permissions.length, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: PermissionItem(
                icon: permissions[index]['icon'],
                text: permissions[index]['text'],
                subtext: permissions[index]['subtext'],
                isSelected: permissionsGranted[index],
                onTap: () {
                  solicitarPermiso(index);
                },
              ),
            );
          }),
          Spacer(),
        ],
      ),
    );
  }
}
