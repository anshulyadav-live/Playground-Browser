import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  BrowserScreenState createState() => BrowserScreenState();
}

class BrowserScreenState extends State<BrowserScreen> {
  late WebViewController _webViewController;
  final TextEditingController _urlController = TextEditingController();
  String _currentUrl = 'https://www.google.com';
  bool _isLoading = true;
  List<String> _bookmarks = [];
  bool _isDesktopMode = false;

  // Desktop user agent string
  final String _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
  // Mobile user agent string
  final String _mobileUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  @override
  void initState() {
    super.initState();
    _urlController.text = _currentUrl;
    _loadSettings();
    _initWebView();
  }

  Future<void> _loadSettings() async {
    await _loadBookmarks();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDesktopMode = prefs.getBool('isDesktopMode') ?? false;
    });
  }

  void _initWebView() {
    final WebViewController controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                setState(() {
                  _isLoading = true;
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  _isLoading = false;
                  _currentUrl = url;
                  _urlController.text = url;
                });
              },
              onWebResourceError: (WebResourceError error) {
                debugPrint('WebView Error: ${error.description}');
              },
            ),
          );

    // Set the user agent based on current mode
    _updateUserAgent(controller);
    controller.loadRequest(Uri.parse(_currentUrl));

    _webViewController = controller;
  }

  void _updateUserAgent(WebViewController controller) {
    controller.setUserAgent(
      _isDesktopMode ? _desktopUserAgent : _mobileUserAgent,
    );
  }

  void _toggleDesktopMode() async {
    setState(() {
      _isDesktopMode = !_isDesktopMode;
    });

    // Save the new setting
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDesktopMode', _isDesktopMode);

    // Update user agent and reload the page
    _updateUserAgent(_webViewController);
    _webViewController.reload();

    // Show feedback to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_isDesktopMode ? 'Desktop' : 'Mobile'} mode enabled',
          ),
        ),
      );
    }
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bookmarks = prefs.getStringList('bookmarks') ?? [];
    });
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarks', _bookmarks);
  }

  void _addBookmark(String url) {
    if (!_bookmarks.contains(url)) {
      setState(() {
        _bookmarks.add(url);
        _saveBookmarks();
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Bookmark added: $url')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This page is already bookmarked')),
        );
      }
    }
  }

  void _navigate(String input) {
    String url;

    // Check if the input is a valid URL
    bool isValidUrl =
        input.startsWith('http://') ||
        input.startsWith('https://') ||
        input.contains('.') && !input.contains(' ');

    if (isValidUrl) {
      // Add https:// if the input doesn't start with http:// or https://
      if (!input.startsWith('http://') && !input.startsWith('https://')) {
        url = 'https://$input';
      } else {
        url = input;
      }
    } else {
      // Treat as a Google search query
      // Encode the input to be URL safe
      String encodedQuery = Uri.encodeComponent(input);
      url = 'https://www.google.com/search?q=$encodedQuery';
    }

    _webViewController.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playground Browser'),
        actions: [
          IconButton(
            icon: Icon(
              _isDesktopMode ? Icons.desktop_windows : Icons.phone_android,
            ),
            onPressed: _toggleDesktopMode,
            tooltip: 'Toggle desktop mode',
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () => _addBookmark(_currentUrl),
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks),
            onPressed: () => _showBookmarks(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAddressBar(),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildAddressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController.reload(),
          ),
          Expanded(
            child: TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'Enter URL or search terms',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _urlController.clear();
                  },
                ),
              ),
              textInputAction: TextInputAction.go,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _navigate(value);
                }
              },
              keyboardType: TextInputType.url,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return BottomAppBar(
      height: 56.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _webViewController.canGoBack()) {
                _webViewController.goBack();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              _webViewController.loadRequest(Uri.parse('https://www.google.com'));
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () async {
              if (await _webViewController.canGoForward()) {
                _webViewController.goForward();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _shareUrl(_currentUrl);
            },
          ),
        ],
      ),
    );
  }

  void _shareUrl(String url) {
    // In a real app, you would use a sharing plugin
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share URL: $url'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // Copy to clipboard functionality would go here
          },
        ),
      ),
    );
  }

  void _showBookmarks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bookmarks',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _bookmarks.isEmpty
                      ? const Center(
                          child: Text('No bookmarks yet'),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _bookmarks.length,
                          itemBuilder: (context, index) {
                            final bookmark = _bookmarks[index];
                            return ListTile(
                              leading: const Icon(Icons.bookmark),
                              title: Text(
                                bookmark,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    _bookmarks.removeAt(index);
                                    _saveBookmarks();
                                  });
                                  Navigator.pop(context);
                                  _showBookmarks();
                                },
                              ),
                              onTap: () {
                                _webViewController.loadRequest(
                                  Uri.parse(bookmark),
                                );
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
