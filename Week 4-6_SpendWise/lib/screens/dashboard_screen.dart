import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../services/chat_service.dart';

/// An animated introductory dashboard that explains what SpendWise is,
/// why it exists, and what it does — presented with a professional,
/// bold visual style and a staggered entrance animation. Also hosts the
/// "Unlock Deep AI Insight" rewarded-ad feature.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;
  bool _isGeneratingInsight = false;

  static const _features = [
    _FeatureItem(
      icon: Icons.add_circle_outline,
      title: 'TRACK EVERY EXPENSE',
      description:
          'Log your daily spending in seconds and always know exactly where your money goes.',
    ),
    _FeatureItem(
      icon: Icons.auto_awesome,
      title: 'AI-POWERED CATEGORIZATION',
      description:
          'Every expense is automatically sorted into the right category — no manual tagging required.',
    ),
    _FeatureItem(
      icon: Icons.receipt_long,
      title: 'SCAN RECEIPTS INSTANTLY',
      description:
          'Snap a photo of any receipt and let AI extract the amount, merchant, and category for you.',
    ),
    _FeatureItem(
      icon: Icons.savings_outlined,
      title: 'SMART BUDGET ALERTS',
      description:
          'Set a monthly budget and get notified before overspending becomes a problem.',
    ),
    _FeatureItem(
      icon: Icons.chat_bubble_outline,
      title: 'ASK YOUR AI ASSISTANT',
      description:
          'Chat naturally to log expenses, ask about your spending, or get quick financial insights.',
    ),
    _FeatureItem(
      icon: Icons.picture_as_pdf_outlined,
      title: 'EXPORT & SHARE REPORTS',
      description:
          'Generate clean, professional PDF summaries of your spending whenever you need them.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _controller.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  Animation<double> _interval(double start, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start.clamp(0, 1), end.clamp(0, 1), curve: Curves.easeOut),
    );
  }

  void _loadRewardedAd() {
    setState(() => _isRewardedAdLoading = true);
    RewardedAd.load(
      adUnitId: AdService.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdLoading = false;
          });
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          setState(() {
            _rewardedAd = null;
            _isRewardedAdLoading = false;
          });
        },
      ),
    );
  }

  Future<void> _unlockDeepInsight() async {
    if (_rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad abhi ready nahi hai — thodi dair baad try karein')),
      );
      if (!_isRewardedAdLoading) _loadRewardedAd();
      return;
    }

    final ad = _rewardedAd!;
    _rewardedAd = null; // prevent double-tap while this one is showing

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd(); // preload the next one
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ad show nahi ho saka. Dobara try karein.')),
          );
        }
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) async {
        setState(() => _isGeneratingInsight = true);
        final insight = await ChatService.getDeepInsight();
        setState(() => _isGeneratingInsight = false);
        if (mounted) _showInsightDialog(insight);
      },
    );
  }

  void _showInsightDialog(String insight) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.auto_awesome, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text(
                    'DEEP AI INSIGHT',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5, color: Colors.indigo),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: SingleChildScrollView(
                  child: Text(
                    insight,
                    style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Got It', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: Colors.indigo,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo, Color(0xFF5C6BC0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: FadeTransition(
                    opacity: _interval(0.0, 0.5),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.account_balance_wallet, color: Colors.white, size: 56),
                          SizedBox(height: 10),
                          Text(
                            'SPENDWISE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'SPEND SMART. SAVE MORE.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Unlock Deep AI Insight — rewarded ad card
                FadeTransition(
                  opacity: _interval(0.05, 0.4),
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
                        .animate(_interval(0.05, 0.4)),
                    child: _insightCard(),
                  ),
                ),
                const SizedBox(height: 16),

                FadeTransition(
                  opacity: _interval(0.1, 0.5),
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
                        .animate(_interval(0.1, 0.5)),
                    child: _sectionCard(
                      title: 'WHAT IS SPENDWISE?',
                      body:
                          'SpendWise is a personal finance companion built to make expense tracking effortless. '
                          'It combines fast, simple expense logging with AI to give you a clear, honest picture of '
                          'your spending — no spreadsheets, no guesswork.',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _interval(0.2, 0.6),
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
                        .animate(_interval(0.2, 0.6)),
                    child: _sectionCard(
                      title: 'WHY SPENDWISE EXISTS',
                      body:
                          'Small, everyday expenses are easy to lose track of — and they add up fast. '
                          'SpendWise closes that gap by building awareness of your habits, keeping you within '
                          'budget, and helping you make confident financial decisions every single day.',
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                FadeTransition(
                  opacity: _interval(0.25, 0.55),
                  child: const Text(
                    'WHAT SPENDWISE DOES',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < _features.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Builder(
                      builder: (_) {
                        final start = 0.3 + (i / _features.length) * 0.6;
                        final end = (start + 0.35).clamp(0.0, 1.0);
                        final anim = _interval(start, end);
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0.12, 0), end: Offset.zero)
                                .animate(anim),
                            child: _featureTile(_features[i]),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 10),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('🎁', style: TextStyle(fontSize: 22)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'UNLOCK DEEP AI INSIGHT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Watch a short ad and get a detailed AI analysis of your spending patterns, plus a practical tip to save more.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGeneratingInsight ? null : _unlockDeepInsight,
              icon: _isGeneratingInsight
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepOrange),
                    )
                  : const Icon(Icons.play_circle_fill, color: Colors.deepOrange),
              label: Text(
                _isGeneratingInsight ? 'Generating Insight...' : 'Watch Ad & Unlock',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required String body}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.indigo,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureTile(_FeatureItem feature) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: Colors.indigo, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, letterSpacing: 0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({required this.icon, required this.title, required this.description});
}