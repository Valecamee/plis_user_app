import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';
import '../services/travel_service.dart';
import '../models/travel_model.dart';
import 'auth/welcome_screen.dart';
import 'detalle_viaje_screen.dart';
import "../../widgets/search/advanced_search_widget.dart";
import '../widgets/search/busqueda_resultados_widget.dart';
import '../../widgets/common/travel_card.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  List<Travel> _travels = [];

  bool _showSearchResults = false;


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.principal,
              AppColors.secundario,
              AppColors.gris50
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header con foto de perfil
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Foto de perfil
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          color: AppColors.principal.withOpacity(0.1),
                          child: const Icon(Icons.person,
                              color: AppColors.principal, size: 30),
                          // TODO: Reemplazar con Image.network(userPhotoUrl)
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('¡Hola! 👋',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text('¿Listo para tu próximo viaje?',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white70)),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: IconButton(
                          onPressed: _handleSignOut,
                          icon: const Icon(Icons.exit_to_app,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),

              // Barra de búsqueda
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: _showSearchResults
                    ? BusquedaResultadosWidget(
                  travels: _travels,

                  onClose: () {
                    setState(() {
                      _showSearchResults = false;
                      _travels = [];
                    });
                  },
                )
                    : AdvancedSearchWidget(
                  onSearch: (query, filters) async {
                    try {
                      final results = await TravelService.advancedSearch(
                        query: query,
                        filters: filters,
                      );
                      setState(() {
                        _travels = results;
                        _showSearchResults = true;
                      });
                    } catch (e) {
                      print('Error al buscar viajes: $e');
                    }
                  },
                  onClear: () {
                    setState(() {
                      _showSearchResults = false;
                      _travels = [];
                    });
                  },
                ),
              ),


              const SizedBox(height: 24),

              // Contenido principal
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.gris50,
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // Mis viajes programados
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Mis viajes programados',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.titulo)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Placeholder mis viajes
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color:
                                    AppColors.secundario.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(50)),
                                child: const Icon(Icons.event_note,
                                    size: 32, color: AppColors.secundario),
                              ),
                              const SizedBox(height: 16),
                              const Text('No tienes viajes programados',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.titulo)),
                              const SizedBox(height: 8),
                              const Text(
                                  'Cuando reserves un viaje aparecerá aquí',
                                  style: TextStyle(
                                      fontSize: 14, color: AppColors.subtitulo),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Viajes disponibles
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Viajes disponibles',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.titulo)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Lista de viajes disponibles desde Firestore (colección 'travels')
                        StreamBuilder<List<Travel>>(
                          stream: TravelService.getAvailableTravelsStream(limit: 4),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              // Mostrar error detallado para debugging
                              print('Error en StreamBuilder: ${snapshot.error}');
                              return Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 32, color: AppColors.error),
                                    const SizedBox(height: 16),
                                    const Text('Error al cargar viajes',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.titulo)),
                                    const SizedBox(height: 8),
                                    Text(
                                      snapshot.error.toString(),
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.subtitulo),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(Icons.search_off,
                                        size: 32, color: AppColors.gris400),
                                    const SizedBox(height: 16),
                                    const Text('No hay viajes disponibles',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.titulo)),
                                  ],
                                ),
                              );
                            }
                            final viajes = snapshot.data!;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: viajes.length,
                              itemBuilder: (context, index) {
                                final viaje = viajes[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetalleViajeScreen(travel: viaje),
                                      ),
                                    );
                                  },
                                  child: TravelCard(
                                    viaje: viaje,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DetalleViajeScreen(travel: viaje),
                                        ),
                                      );
                                    },
                                  ),

                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Acciones rápidas
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Acciones rápidas',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.titulo)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildActionCard(Icons.history, 'Historial',
                                      'Viajes anteriores', AppColors.gris600),
                                  const SizedBox(width: 16),
                                  _buildActionCard(
                                      Icons.pending_actions,
                                      'En curso',
                                      'Viajes activos',
                                      AppColors.principal),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildActionCard(
      IconData icon, String title, String subtitle, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.titulo)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.subtitulo)),
            ],
          ),
        ),
      ),
    );
  }
}