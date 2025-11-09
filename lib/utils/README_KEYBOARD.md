# KeyboardUtils - Utilidad para manejo del teclado

## Descripción
`KeyboardUtils` es una clase utilitaria que centraliza el manejo del teclado en toda la aplicación, previniendo problemas de overflow y mejorando la experiencia de usuario durante las transiciones del teclado.

## ¿Por qué existe?
El problema de overflow del teclado se repetía en múltiples pantallas. Esta utilidad:
- ✅ Centraliza la lógica en un solo lugar
- ✅ Evita código duplicado
- ✅ Define tiempos estándar de espera (150ms por defecto)
- ✅ Previene overflow durante transiciones
- ✅ Mejora la experiencia de usuario con transiciones suaves

## Uso básico

### 1. Ocultar el teclado
```dart
// Simple
KeyboardUtils.hideKeyboard(context);

// Con delay personalizado
KeyboardUtils.hideKeyboard(context, delayMs: 200);
```

### 2. Ocultar teclado y ejecutar acción
```dart
KeyboardUtils.hideKeyboardAndThen(
  context,
  () {
    // Tu acción aquí (ej: cambiar estado, navegar, etc.)
    setState(() => _showFilters = !_showFilters);
  },
);
```

### 3. Alternar estado con manejo de teclado
```dart
KeyboardUtils.toggleWithKeyboard(
  context,
  _showFilters,
  (newValue) => setState(() => _showFilters = newValue),
);
```

### 4. Verificar si el teclado está visible
```dart
if (KeyboardUtils.isKeyboardVisible(context)) {
  // Hacer algo cuando el teclado está visible
}
```

### 5. Cambiar foco entre campos
```dart
KeyboardUtils.changeFocus(
  context,
  _currentFocusNode,
  _nextFocusNode,
);
```

## Tiempo estándar
El delay por defecto es de **150ms**, que es el tiempo óptimo para:
- Permitir que el teclado se cierre suavemente
- Evitar overflow visual
- Mantener una UX fluida

Puedes ajustar este tiempo usando el parámetro `delayMs` si necesitas más o menos tiempo.

## Ejemplos en el código

### Ejemplo 1: Toggle de filtros
```dart
void _toggleFilters() {
  KeyboardUtils.hideKeyboardAndThen(
    context,
    () {
      if (mounted) {
        setState(() => _showFilters = !_showFilters);
      }
    },
  );
}
```

### Ejemplo 2: Búsqueda con teclado
```dart
void _performSearch() {
  KeyboardUtils.hideKeyboardAndThen(
    context,
    () {
      // Realizar búsqueda
      widget.onSearch(_searchText, filters);
    },
    delayMs: 100, // Delay más corto para búsqueda
  );
}
```

### Ejemplo 3: TextField con manejo de filtros
```dart
TextField(
  onTap: () {
    if (_showFilters) {
      KeyboardUtils.hideKeyboardAndThen(
        context,
        () {
          if (mounted) {
            setState(() => _showFilters = false);
          }
        },
      );
    }
  },
  onSubmitted: (_) {
    KeyboardUtils.hideKeyboard(context);
    _performSearch();
  },
)
```

## Métodos disponibles

| Método | Descripción | Parámetros |
|--------|-------------|------------|
| `hideKeyboard` | Oculta el teclado inmediatamente | `context`, `delayMs` (opcional) |
| `hideKeyboardAndThen` | Oculta teclado y ejecuta callback | `context`, `onComplete`, `delayMs` (opcional) |
| `toggleWithKeyboard` | Alterna estado manejando teclado | `context`, `currentState`, `onToggle`, `delayMs` (opcional) |
| `isKeyboardVisible` | Verifica si teclado está visible | `context` |
| `getKeyboardHeight` | Obtiene altura del teclado | `context` |
| `unfocusAll` | Desenfoca todos los campos | `context` |
| `focusWithDelay` | Enfoca un campo con delay | `focusNode`, `delayMs` (opcional) |
| `changeFocus` | Cambia foco entre campos | `context`, `currentFocus`, `nextFocus`, `delayMs` (opcional) |

## Buenas prácticas

1. **Siempre usar antes de cambiar estado**: Si vas a mostrar/ocultar widgets, primero oculta el teclado
2. **Usar en onSubmitted**: Siempre oculta el teclado cuando el usuario envía un formulario
3. **Verificar mounted**: Usa `if (mounted)` dentro de callbacks asíncronos
4. **Ajustar delay según necesidad**: Búsquedas pueden usar 100ms, cambios de vista 150ms
5. **No llamar múltiples veces seguidas**: Una llamada es suficiente

## Prevención de overflow

Para prevenir overflow al usar con widgets que cambian de altura:

```dart
// En tu LayoutBuilder
final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
final availableHeight = screenHeight - keyboardHeight;

Container(
  constraints: BoxConstraints(
    maxHeight: keyboardHeight > 0 
        ? availableHeight * 0.35  // Con teclado
        : availableHeight * 0.55, // Sin teclado
  ),
  // ...
)
```

## Archivos que usan KeyboardUtils
- `lib/widgets/search/advanced_search_widget.dart`
- (Agregar otros archivos aquí según se vayan migrando)

## Migración de código antiguo

❌ **Antes:**
```dart
void _toggleFilters() {
  _searchFocusNode.unfocus();
  FocusScope.of(context).unfocus();
  Future.delayed(const Duration(milliseconds: 150), () {
    if (mounted) {
      setState(() => _showFilters = !_showFilters);
    }
  });
}
```

✅ **Después:**
```dart
void _toggleFilters() {
  KeyboardUtils.hideKeyboardAndThen(context, () {
    if (mounted) {
      setState(() => _showFilters = !_showFilters);
    }
  });
}
```

## Contribuir
Si encuentras un nuevo caso de uso para el manejo del teclado, considera agregarlo a `KeyboardUtils` en lugar de duplicar código.
