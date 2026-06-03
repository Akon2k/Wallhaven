# Project Status: Wallhaven Explorer

Este documento es la Fuente de Verdad para el estado del desarrollo de acuerdo con el framework FDA-IA.

## Backlog de Puntos de Trabajo

- [x] **Fase 1: Inicialización del Proyecto y Contratos** | *AkonDeV 03/06/2026*
- [x] **Fase 2: Implementación de Lógica y Persistencia SQLite Base** | *AkonDeV 03/06/2026*
- [x] **Punto 1: Sistema de Configuración y SettingsWindow Funcional** | *AkonDeV 03/06/2026*
  - Diseño: Persistencia de configuración en `config.json` e inyección de dependencias.
  - UI: Ventana de configuración que permite modificar API Key, carpetas y tema (claro/oscuro).
  - Testing: Pruebas de guardado/lectura de configuración.
- [x] **Punto 2: Caché Local de Imágenes e Interfaz de Visualización con Zoom** | *AkonDeV 03/06/2026*
  - Diseño: Control de caché local e integración con visualizador.
  - UI: Visualización avanzada, soporte para zoom con rueda, ajuste automático y tamaño real.
- [x] **Punto 3: Búsqueda con Filtros Completos y Paginación** | *AkonDeV 03/06/2026*
  - Diseño: Vinculación de query string avanzada y límites de API.
  - UI: Panel de filtros (Categorías, Purity, Ordenación) y barra de paginación.
- [x] **Punto 4: Redimensionador Móvil Avanzado** | *AkonDeV 03/06/2026*
  - Diseño: Orquestación de recorte y padding en ImageSharp.
  - UI: Selector de relación de aspecto y resolución móvil.
- [ ] **Punto 5: Gestión de Favoritos e Historial Local**
  - Diseño: SQLite CRUD completo e historial de búsquedas recientes.
  - UI: Vista lateral de favoritos y buscador histórico.
- [ ] **Punto 6: Características Extra (Slideshow, Pantalla Completa, Portapapeles, Navegador)**
  - Diseño: Temporizadores de slideshow y llamadas a procesos del sistema.
