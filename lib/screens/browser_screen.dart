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
        title: const Text('Playground Brouszer'),
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
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: 'Enter URL',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: (value) {
                _navigate(value);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _navigate(_urlController.text);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return BottomAppBar(
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
            icon: const Icon(Icons.arrow_forward),
            onPressed: () async {
              if (await _webViewController.canGoForward()) {
                _webViewController.goForward();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _webViewController.reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              _navigate('https://www.google.com');
            },
          ),
        ],
      ),
    );
  }

  void _showBookmarks() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _bookmarks.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_bookmarks[index]),
              onTap: () {
                Navigator.pop(context);
                _navigate(_bookmarks[index]);
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _bookmarks.removeAt(index);
                    _saveBookmarks();
                  });
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bookmark removed')),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
