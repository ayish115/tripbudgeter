import 'package:flutter/material.dart';
import 'package:tripbudgeter/User/mainlayout.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  void _goToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainLayout()),
    );
  }

  static const Color mainTeal = Color.fromARGB(255, 1, 177, 165);
  static const Color lightTeal = Color.fromARGB(255, 71, 230, 214);
  static const Color softGreen = Color.fromARGB(255, 120, 225, 173);
  static const Color mutedBlue = Color.fromARGB(255, 59, 198, 156);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnboardingPagePresenter(
        onSkip: () => _goToHome(context),
        onFinish: () => _goToHome(context),
        pages: [
          OnboardingPageModel(
            title: 'Smart Trip Budgeting',
            description:
                'Create and manage detailed budgets for every trip, so you never overspend.',
            imageUrl: 'https://i.ibb.co/cJqsPSB/scooter.png',
            bgColor: mainTeal,
            textColor: Colors.white,
          ),
          OnboardingPageModel(
            title: 'Track Expenses Easily',
            description:
                'Log your travel expenses on-the-go: transport, food, accommodation and more.',
            imageUrl: 'https://i.ibb.co/cJqsPSB/scooter.png',
            bgColor: lightTeal,
            textColor: Colors.white,
          ),
          OnboardingPageModel(
            title: 'Analyze Spending',
            description:
                'Visualize your spending patterns and optimize your travel budget smartly.',
            imageUrl: 'https://i.ibb.co/cJqsPSB/scooter.png',
            bgColor: softGreen,
            textColor: Colors.white,
          ),
          OnboardingPageModel(
            title: 'Plan & Enjoy Stress-Free Trips',
            description:
                'Keep all your trip finances under control and focus on creating memories.',
            imageUrl: 'https://i.ibb.co/cJqsPSB/scooter.png',
            bgColor: mutedBlue,
            textColor: Colors.white,
          ),
        ], // <--- Closing the pages list here
      ),
    );
  }
}

class OnboardingPagePresenter extends StatefulWidget {
  final List<OnboardingPageModel> pages;
  final VoidCallback? onSkip;
  final VoidCallback? onFinish;

  const OnboardingPagePresenter({
    super.key,
    required this.pages,
    this.onSkip,
    this.onFinish,
  });

  @override
  State<OnboardingPagePresenter> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPagePresenter> {
  int _currentPage = 0;
  final PageController _pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        color: widget.pages[_currentPage].bgColor,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.pages.length,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPage = idx;
                    });
                  },
                  itemBuilder: (context, idx) {
                    final item = widget.pages[idx];
                    return Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Image.network(item.imageUrl),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  item.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: item.textColor,
                                      ),
                                ),
                              ),
                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 280,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  item.description,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: item.textColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.pages
                    .map(
                      (item) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: _currentPage == widget.pages.indexOf(item)
                            ? 30
                            : 8,
                        height: 8,
                        margin: const EdgeInsets.all(2.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    )
                    .toList(),
              ),

              SizedBox(
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: widget.onSkip,
                      child: const Text("Skip"),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        if (_currentPage == widget.pages.length - 1) {
                          widget.onFinish?.call();
                        } else {
                          _pageController.animateToPage(
                            _currentPage + 1,
                            curve: Curves.easeInOutCubic,
                            duration: const Duration(milliseconds: 250),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            _currentPage == widget.pages.length - 1
                                ? "Finish"
                                : "Next",
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == widget.pages.length - 1
                                ? Icons.done
                                : Icons.arrow_forward,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPageModel {
  final String title;
  final String description;
  final String imageUrl;
  final Color bgColor;
  final Color textColor;

  OnboardingPageModel({
    required this.title,
    required this.description,
    required this.imageUrl,
    this.bgColor = Colors.blue,
    this.textColor = Colors.white,
  });
}
