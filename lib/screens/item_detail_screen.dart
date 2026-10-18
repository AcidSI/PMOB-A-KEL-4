import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/lost_item.dart';

class ItemDetailScreen extends StatelessWidget {
  final LostItem item;
  const ItemDetailScreen({super.key, required this.item});

  IconData _getIcon(String category) {
    switch (category) {
      case 'laptop':
        return Icons.laptop_rounded;
      case 'phone':
        return Icons.smartphone_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'glasses':
        return Icons.visibility_rounded;
      case 'bag':
        return Icons.backpack_rounded;
      case 'battery':
        return Icons.battery_charging_full_rounded;
      case 'earphone':
        return Icons.headphones_rounded;
      case 'jacket':
        return Icons.dry_cleaning_rounded;
      case 'storage':
        return Icons.usb_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'charger':
        return Icons.cable_rounded;
      case 'bicycle':
        return Icons.directions_bike_rounded;
      case 'key':
        return Icons.key_rounded;
      case 'tablet':
        return Icons.tablet_rounded;
      case 'watch':
        return Icons.watch_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'laptop':
        return const Color(0xFF045436);
      case 'phone':
        return const Color(0xFF00897B);
      case 'wallet':
        return const Color(0xFF6D4C41);
      case 'glasses':
        return const Color(0xFF546E7A);
      case 'bag':
        return const Color(0xFF1565C0);
      case 'battery':
        return const Color(0xFF2E7D32);
      case 'earphone':
        return const Color(0xFF6A1B9A);
      case 'jacket':
        return const Color(0xFFC62828);
      case 'storage':
        return const Color(0xFFE65100);
      case 'book':
        return const Color(0xFF558B2F);
      case 'charger':
        return const Color(0xFF37474F);
      case 'bicycle':
        return const Color(0xFF00838F);
      case 'key':
        return const Color(0xFFF57F17);
      case 'tablet':
        return const Color(0xFF4527A0);
      case 'watch':
        return const Color(0xFF880E4F);
      default:
        return const Color(0xFF045436);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(item.iconCategory);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(item.iconCategory),
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.namaBarang,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ID: ${item.id}',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: 'Informasi Barang',
                    color: color,
                    children: [
                      _buildDetailRow(
                        icon: Icons.label_rounded,
                        label: 'Nama Barang',
                        value: item.namaBarang,
                        color: color,
                      ),
                      _buildDetailRow(
                        icon: Icons.palette_rounded,
                        label: 'Warna',
                        value: item.warna,
                        color: color,
                      ),
                      _buildDetailRow(
                        icon: Icons.branding_watermark_rounded,
                        label: 'Merek',
                        value: item.merek,
                        color: color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    title: 'Lokasi & Waktu',
                    color: color,
                    children: [
                      _buildDetailRow(
                        icon: Icons.location_on_rounded,
                        label: 'Lokasi Terakhir',
                        value: item.lokasi,
                        color: color,
                      ),
                      _buildDetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Tanggal Hilang',
                        value: item.tanggalHilang,
                        color: color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    title: 'Deskripsi',
                    color: color,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        child: Text(
                          item.deskripsi,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    title: 'Pelapor',
                    color: color,
                    children: [
                      _buildDetailRow(
                        icon: Icons.person_rounded,
                        label: 'Nama Pelapor',
                        value: item.pelapor,
                        color: color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Contact button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.75)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Menghubungi ${item.pelapor}...',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: color,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.message_rounded,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Hubungi Pelapor',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFF045436),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
