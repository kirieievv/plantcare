import 'package:flutter/material.dart';
import '../utils/notification_test.dart';
import '../utils/web_push_tester.dart';
import '../utils/web_notification_helper_stub.dart'
    if (dart.library.html) '../utils/web_notification_helper.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  Map<String, dynamic>? _testResults;
  bool _isLoading = false;
  String? _error;

  String _tr({
    required String en,
    required String es,
    required String fr,
  }) {
    final code = Localizations.localeOf(context).languageCode;
    if (code == 'es') return es;
    if (code == 'fr') return fr;
    return en;
  }

  void _showSnackBar(SnackBar snackBar) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _showAppDialog(WidgetBuilder builder) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: builder,
    );
  }

  @override
  void initState() {
    super.initState();
    _runNotificationTest();
  }

  Future<void> _runNotificationTest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await NotificationTest.getNotificationStatus();
      setState(() {
        _testResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await NotificationTest.sendTestNotification();
      if (results['success']) {
        _showSnackBar(
          SnackBar(
            content: Text(
              results['message'] ??
                  _tr(
                    en: 'Test notification sent!',
                    es: 'Notificacion de prueba enviada!',
                    fr: 'Notification de test envoyee !',
                  ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _error = results['error'];
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showWebTestNotification() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await NotificationTest.showWebTestNotification();
      if (results['success']) {
        _showSnackBar(
          SnackBar(
            content: Text(
              results['message'] ??
                  _tr(
                    en: 'Web test notification shown!',
                    es: 'Notificacion web de prueba mostrada!',
                    fr: 'Notification web de test affichee !',
                  ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _error = results['error'];
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFCMToken() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await WebPushTester.refreshFCMToken();
      
      if (result['success'] == true) {
        // Update the test results with the new token
        setState(() {
          if (_testResults != null) {
            _testResults!['token'] = result['token'];
            _testResults!['tokenLength'] = result['tokenLength'];
          } else {
            // If no test results exist, create them
            _testResults = {
              'token': result['token'],
              'tokenLength': result['tokenLength'],
              'success': true,
            };
          }
        });
        
        _showSnackBar(
          SnackBar(
            content: Text(
              '${_tr(en: 'FCM token refreshed successfully!', es: 'Token FCM actualizado correctamente!', fr: 'Jeton FCM actualise avec succes !')} '
              '${_tr(en: 'Length', es: 'Longitud', fr: 'Longueur')}: ${result['tokenLength']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showSnackBar(
          SnackBar(
            content: Text(
              '${_tr(en: 'Failed to refresh token', es: 'No se pudo actualizar el token', fr: 'Echec de l actualisation du jeton')}: ${result['error']}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _showSnackBar(
        SnackBar(
          content: Text(
            '${_tr(en: 'Error refreshing token', es: 'Error al actualizar el token', fr: 'Erreur lors de l actualisation du jeton')}: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAllTokens() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await WebPushTester.getAllUserTokens();
      
      if (result['success'] == true) {
        final tokens = result['tokens'] as List<String>;
        final tokenCount = result['tokenCount'] as int;
        final lastUpdate = result['lastTokenUpdate'] as String?;
        
        _showSnackBar(
          SnackBar(
            content: Text(
              '${_tr(en: 'Found', es: 'Encontrados', fr: 'Trouves')} $tokenCount FCM '
              '${_tr(en: 'tokens', es: 'tokens', fr: 'jetons')}. '
              '${_tr(en: 'Last update', es: 'Ultima actualizacion', fr: 'Derniere mise a jour')}: $lastUpdate',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Show tokens in a dialog
        _showAppDialog(
          (context) => AlertDialog(
            title: Text(_tr(en: 'All FCM Tokens', es: 'Todos los tokens FCM', fr: 'Tous les jetons FCM')),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${_tr(en: 'Token Count', es: 'Cantidad de tokens', fr: 'Nombre de jetons')}: $tokenCount'),
                  if (lastUpdate != null) Text('${_tr(en: 'Last Update', es: 'Ultima actualizacion', fr: 'Derniere mise a jour')}: $lastUpdate'),
                  const SizedBox(height: 16),
                  ...tokens.asMap().entries.map((entry) {
                    final index = entry.key;
                    final token = entry.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_tr(en: 'Token', es: 'Token', fr: 'Jeton')} $index:', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SelectableText(
                            token,
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_tr(en: 'Close', es: 'Cerrar', fr: 'Fermer')),
              ),
            ],
          ),
        );
      } else {
        _showSnackBar(
          SnackBar(
            content: Text(
              '${_tr(en: 'Failed to get tokens', es: 'No se pudieron obtener los tokens', fr: 'Impossible de recuperer les jetons')}: ${result['error']}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _showSnackBar(
        SnackBar(
          content: Text(
            '${_tr(en: 'Error getting tokens', es: 'Error obteniendo tokens', fr: 'Erreur lors de la recuperation des jetons')}: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendSimpleTest() async {
    if (_testResults?['token'] == null) {
      _showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              en: 'No FCM token available. Please refresh the test first.',
              es: 'No hay token FCM disponible. Actualiza la prueba primero.',
              fr: 'Aucun jeton FCM disponible. Actualisez d abord le test.',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await WebPushTester.sendTestNotificationSimple(
        fcmToken: _testResults!['token'],
      );

      if (result['success'] == true) {
        _showSnackBar(
          SnackBar(
            content: Text(
              '${result['message']} - ${_tr(en: 'Token length', es: 'Longitud del token', fr: 'Longueur du jeton')}: ${result['tokenLength']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _error = result['error'];
        });
        _showSnackBar(
          SnackBar(
            content: Text(
              '${_tr(en: 'Simple test failed', es: 'La prueba simple fallo', fr: 'Le test simple a echoue')}: ${result['error']}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _showSnackBar(
        SnackBar(
          content: Text('${_tr(en: 'Error', es: 'Error', fr: 'Erreur')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearBrowserCache() async {
    _showSnackBar(
      SnackBar(
        content: Text(
          _tr(
            en: 'Please manually clear your browser cache and reload the page',
            es: 'Borra manualmente la cache del navegador y recarga la pagina',
            fr: 'Videz manuellement le cache du navigateur puis rechargez la page',
          ),
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );
    
    // Show instructions dialog
    _showAppDialog(
      (context) => AlertDialog(
        title: Text(_tr(en: 'Clear Browser Cache', es: 'Limpiar cache del navegador', fr: 'Vider le cache du navigateur')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tr(en: 'To clear browser cache:', es: 'Para limpiar la cache del navegador:', fr: 'Pour vider le cache du navigateur :')),
            const SizedBox(height: 8),
            Text(_tr(en: '1. Press Ctrl+Shift+R (or Cmd+Shift+R on Mac)', es: '1. Pulsa Ctrl+Shift+R (o Cmd+Shift+R en Mac)', fr: '1. Appuyez sur Ctrl+Shift+R (ou Cmd+Shift+R sur Mac)')),
            Text(_tr(en: '2. Or go to Settings → Privacy → Clear browsing data', es: '2. O ve a Configuracion → Privacidad → Borrar datos de navegacion', fr: '2. Ou allez dans Reglages → Confidentialite → Effacer les donnees de navigation')),
            Text(_tr(en: '3. Or close and reopen the browser tab', es: '3. O cierra y vuelve a abrir la pestana del navegador', fr: '3. Ou fermez et rouvrez l onglet du navigateur')),
            const SizedBox(height: 8),
            Text(_tr(en: 'This will help clear cached FCM tokens.', es: 'Esto ayudara a limpiar tokens FCM en cache.', fr: 'Cela aidera a effacer les jetons FCM en cache.')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_tr(en: 'OK', es: 'OK', fr: 'OK')),
          ),
        ],
      ),
    );
  }

  Future<void> _forceNewToken() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await WebPushTester.forceNewToken();

      if (result['success'] == true) {
        // Update the test results with the new token
        setState(() {
          if (_testResults != null) {
            _testResults!['token'] = result['token'];
            _testResults!['tokenLength'] = result['tokenLength'];
          } else {
            // If no test results exist, create them
            _testResults = {
              'token': result['token'],
              'tokenLength': result['tokenLength'],
              'success': true,
            };
          }
        });
        
        _showSnackBar(
          SnackBar(
            content: Text(
              '${_tr(en: 'New token generated!', es: 'Nuevo token generado!', fr: 'Nouveau jeton genere !')} '
              '${_tr(en: 'Length', es: 'Longitud', fr: 'Longueur')}: ${result['tokenLength']}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Automatically test the new token
        await Future.delayed(const Duration(seconds: 1));
        await _sendWebPushTest();
        
      } else {
        setState(() {
          _error = result['error'];
        });
        _showSnackBar(
          SnackBar(
            content: Text(
              '${_tr(en: 'Failed to generate new token', es: 'No se pudo generar un nuevo token', fr: 'Impossible de generer un nouveau jeton')}: ${result['error']}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _showSnackBar(
        SnackBar(
          content: Text(
            '${_tr(en: 'Error generating new token', es: 'Error al generar nuevo token', fr: 'Erreur lors de la generation d un nouveau jeton')}: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testToken0() async {
    await _testTokenByIndex(0);
  }

  Future<void> _testToken1() async {
    await _testTokenByIndex(1);
  }

  Future<void> _testTokenByIndex(int index) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await WebPushTester.testTokenByIndex(tokenIndex: index);

      if (result['success'] == true) {
        _showSnackBar(
          SnackBar(
            content: Text(
              '${_tr(en: 'Token', es: 'Token', fr: 'Jeton')} $index ${_tr(en: 'test successful!', es: 'probado con exito!', fr: 'teste avec succes !')}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _error = result['error'];
        });
        _showSnackBar(
          SnackBar(
            content: Text(
              '${_tr(en: 'Token', es: 'Token', fr: 'Jeton')} $index ${_tr(en: 'test failed', es: 'fallo en la prueba', fr: 'a echoue au test')}: ${result['error']}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _showSnackBar(
        SnackBar(
          content: Text(
            '${_tr(en: 'Error testing token', es: 'Error al probar el token', fr: 'Erreur lors du test du jeton')} $index: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendSafariNotification() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await WebNotificationHelper.sendSafariNotification(
        title: _tr(
          en: 'Plant Care Safari Test 🌱',
          es: 'Prueba Safari de Plant Care 🌱',
          fr: 'Test Safari Plant Care 🌱',
        ),
        body: _tr(
          en: 'This is a Safari-compatible notification!',
          es: 'Esta es una notificacion compatible con Safari!',
          fr: 'Ceci est une notification compatible Safari !',
        ),
        icon: '/icons/Icon-192.png',
      );

      if (result) {
        _showSnackBar(
          SnackBar(
            content: Text(
              _tr(
                en: 'Safari notification sent! Check for popup.',
                es: 'Notificacion Safari enviada! Revisa el popup.',
                fr: 'Notification Safari envoyee ! Verifiez le popup.',
              ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        _showSnackBar(
          SnackBar(
            content: Text(
              _tr(
                en: 'Safari notification failed. Check permissions.',
                es: 'Fallo la notificacion de Safari. Revisa permisos.',
                fr: 'Echec de la notification Safari. Verifiez les autorisations.',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _showSnackBar(
        SnackBar(
          content: Text('${_tr(en: 'Error', es: 'Error', fr: 'Erreur')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendAndVerifyNotification() async {
    if (_testResults?['token'] == null) {
      _showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              en: 'No FCM token available. Please refresh the test first.',
              es: 'No hay token FCM disponible. Actualiza la prueba primero.',
              fr: 'Aucun jeton FCM disponible. Actualisez d abord le test.',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Send the notification
      final result = await WebPushTester.sendTestNotification(
        fcmToken: _testResults!['token'],
        title: _tr(
          en: 'Plant Care Test 🌱',
          es: 'Prueba de Plant Care 🌱',
          fr: 'Test Plant Care 🌱',
        ),
        body: _tr(
          en: 'This is a test notification! Did you see it?',
          es: 'Esta es una notificacion de prueba! La viste?',
          fr: 'Ceci est une notification de test ! L avez-vous vue ?',
        ),
      );

      if (result['success'] == true) {
        // Show success message
        _showSnackBar(
          SnackBar(
            content: Text(
              _tr(
                en: 'Notification sent successfully! Check for popup.',
                es: 'Notificacion enviada correctamente! Revisa el popup.',
                fr: 'Notification envoyee avec succes ! Verifiez le popup.',
              ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Show verification dialog
        await Future.delayed(const Duration(seconds: 2));
        _showAppDialog(
          (context) => AlertDialog(
            title: Text(_tr(en: 'Did You See the Notification?', es: 'Viste la notificacion?', fr: 'Avez-vous vu la notification ?')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_tr(en: 'Please check:', es: 'Por favor revisa:', fr: 'Veuillez verifier :')),
                const SizedBox(height: 8),
                Text(_tr(en: '1. Did a notification popup appear?', es: '1. Aparecio un popup de notificacion?', fr: '1. Une popup de notification est-elle apparue ?')),
                Text(_tr(en: '2. Check your browser\'s notification center', es: '2. Revisa el centro de notificaciones del navegador', fr: '2. Verifiez le centre de notifications du navigateur')),
                Text(_tr(en: '3. Look for a Plant Care notification', es: '3. Busca una notificacion de Plant Care', fr: '3. Cherchez une notification Plant Care')),
                const SizedBox(height: 8),
                Text(_tr(en: 'If you didn\'t see it, the notification might be blocked or the service worker isn\'t working properly.', es: 'Si no la viste, la notificacion puede estar bloqueada o el service worker no funciona bien.', fr: 'Si vous ne l avez pas vue, la notification peut etre bloquee ou le service worker ne fonctionne pas correctement.')),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_tr(en: 'I saw it!', es: 'La vi!', fr: 'Je l ai vue !')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSnackBar(
                    SnackBar(
                      content: Text(
                        _tr(
                          en: 'Notification might be blocked. Check browser settings.',
                          es: 'La notificacion puede estar bloqueada. Revisa la configuracion del navegador.',
                          fr: 'La notification peut etre bloquee. Verifiez les reglages du navigateur.',
                        ),
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: Text(_tr(en: 'I didn\'t see it', es: 'No la vi', fr: 'Je ne l ai pas vue')),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _error = result['error'];
        });
        _showSnackBar(
          SnackBar(
            content: Text(
              '${_tr(en: 'Failed to send notification', es: 'No se pudo enviar la notificacion', fr: 'Echec de l envoi de la notification')}: ${result['error']}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _showSnackBar(
        SnackBar(
          content: Text('${_tr(en: 'Error', es: 'Error', fr: 'Erreur')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendWebPushTest() async {
    if (_testResults?['token'] == null) {
      _showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              en: 'No FCM token available. Please refresh the test first.',
              es: 'No hay token FCM disponible. Actualiza la prueba primero.',
              fr: 'Aucun jeton FCM disponible. Actualisez d abord le test.',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await WebPushTester.sendTestNotification(
        fcmToken: _testResults!['token'],
        title: _tr(
          en: 'Plant Care Push Test',
          es: 'Prueba push de Plant Care',
          fr: 'Test push Plant Care',
        ),
        body: _tr(
          en: 'This is a real push notification via FCM! 🎉',
          es: 'Esta es una notificacion push real via FCM! 🎉',
          fr: 'Ceci est une vraie notification push via FCM ! 🎉',
        ),
      );
      
      if (results['success']) {
        _showSnackBar(
          SnackBar(
            content: Text(
              results['message'] ??
                  _tr(
                    en: 'Push notification sent!',
                    es: 'Notificacion push enviada!',
                    fr: 'Notification push envoyee !',
                  ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        setState(() {
          _error = results['error'];
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tr(
            en: 'Notification Test',
            es: 'Prueba de notificaciones',
            fr: 'Test des notifications',
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runNotificationTest,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _testResults?['success'] == true
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: _testResults?['success'] == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _tr(
                                  en: 'Notification Status',
                                  es: 'Estado de notificaciones',
                                  fr: 'Etat des notifications',
                                ),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Text(
                                '${_tr(en: 'Error', es: 'Error', fr: 'Erreur')}: $_error',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Test Results
                  if (_testResults != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tr(
                                en: 'Test Results',
                                es: 'Resultados de prueba',
                                fr: 'Resultats du test',
                              ),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(_tr(en: 'Platform', es: 'Plataforma', fr: 'Plateforme'), _testResults!['platform']),
                            _buildInfoRow(_tr(en: 'Is Web', es: 'Es web', fr: 'Est web'), _testResults!['isWeb'].toString()),
                            _buildInfoRow(_tr(en: 'Success', es: 'Exito', fr: 'Succes'), _testResults!['success'].toString()),
                            if (_testResults!['permissionStatus'] != null)
                              _buildInfoRow(_tr(en: 'Permission', es: 'Permiso', fr: 'Autorisation'), _testResults!['permissionStatus']),
                            if (_testResults!['alert'] != null)
                              _buildInfoRow(_tr(en: 'Alert Permission', es: 'Permiso de alerta', fr: 'Autorisation d alerte'), _testResults!['alert'].toString()),
                            if (_testResults!['badge'] != null)
                              _buildInfoRow(_tr(en: 'Badge Permission', es: 'Permiso de insignia', fr: 'Autorisation de badge'), _testResults!['badge'].toString()),
                            if (_testResults!['sound'] != null)
                              _buildInfoRow(_tr(en: 'Sound Permission', es: 'Permiso de sonido', fr: 'Autorisation du son'), _testResults!['sound'].toString()),
                            if (_testResults!['token'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _tr(en: 'FCM Token:', es: 'Token FCM:', fr: 'Jeton FCM :'),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: SelectableText(
                                  _testResults!['token'],
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (_testResults!['tokenLength'] != null)
                              _buildInfoRow(_tr(en: 'Token Length', es: 'Longitud del token', fr: 'Longueur du jeton'), _testResults!['tokenLength'].toString()),
                            _buildInfoRow(_tr(en: 'User Logged In', es: 'Usuario conectado', fr: 'Utilisateur connecte'), _testResults!['userLoggedIn'].toString()),
                            if (_testResults!['userId'] != null)
                              _buildInfoRow(_tr(en: 'User ID', es: 'ID de usuario', fr: 'ID utilisateur'), _testResults!['userId']),
                            if (_testResults!['userEmail'] != null)
                              _buildInfoRow(_tr(en: 'User Email', es: 'Correo del usuario', fr: 'E-mail utilisateur'), _testResults!['userEmail']),
                            _buildInfoRow(_tr(en: 'Watering Reminders', es: 'Recordatorios de riego', fr: 'Rappels d arrosage'), _testResults!['wateringReminders'].toString()),
                            if (_testResults!['isMobileSafari'] != null)
                              _buildInfoRow(_tr(en: 'Mobile Safari', es: 'Safari movil', fr: 'Safari mobile'), _testResults!['isMobileSafari'].toString()),
                            if (_testResults!['isMacOSSafari'] != null)
                              _buildInfoRow('macOS Safari', _testResults!['isMacOSSafari'].toString()),
                            if (_testResults!['webPermission'] != null)
                              _buildInfoRow(_tr(en: 'Web Permission', es: 'Permiso web', fr: 'Autorisation web'), _testResults!['webPermission']),
                            if (_testResults!['notificationSupport'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _tr(en: 'Browser Support:', es: 'Compatibilidad del navegador:', fr: 'Compatibilite du navigateur :'),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              if (_testResults!['notificationSupport']['supported'] != null)
                                _buildInfoRow('  ${_tr(en: 'Supported', es: 'Compatible', fr: 'Pris en charge')}', _testResults!['notificationSupport']['supported'].toString()),
                              if (_testResults!['notificationSupport']['browser'] != null)
                                _buildInfoRow('  ${_tr(en: 'Browser', es: 'Navegador', fr: 'Navigateur')}', _testResults!['notificationSupport']['browser']),
                            ],
                            if (_testResults!['tokenError'] != null)
                              _buildInfoRow(_tr(en: 'Token Error', es: 'Error de token', fr: 'Erreur de jeton'), _testResults!['tokenError']),
                            if (_testResults!['recommendation'] != null)
                              _buildInfoRow(_tr(en: 'Recommendation', es: 'Recomendacion', fr: 'Recommandation'), _testResults!['recommendation']),
                            _buildInfoRow(_tr(en: 'Timestamp', es: 'Marca de tiempo', fr: 'Horodatage'), _testResults!['timestamp']),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _sendTestNotification,
                                icon: const Icon(Icons.send),
                                label: Text(_tr(en: 'Send FCM Test', es: 'Enviar prueba FCM', fr: 'Envoyer test FCM')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _runNotificationTest,
                                icon: const Icon(Icons.refresh),
                                label: Text(_tr(en: 'Refresh Test', es: 'Actualizar prueba', fr: 'Actualiser le test')),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showWebTestNotification,
                            icon: const Icon(Icons.web),
                            label: Text(_tr(en: 'Show Web Test Notification', es: 'Mostrar notificacion web de prueba', fr: 'Afficher une notification web de test')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _refreshFCMToken,
                      icon: const Icon(Icons.refresh),
                      label: Text(_tr(en: 'Refresh FCM Token', es: 'Actualizar token FCM', fr: 'Actualiser le jeton FCM')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showAllTokens,
                      icon: const Icon(Icons.list),
                      label: Text(_tr(en: 'Show All Tokens', es: 'Mostrar todos los tokens', fr: 'Afficher tous les jetons')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendSimpleTest,
                      icon: const Icon(Icons.check_circle),
                      label: Text(_tr(en: 'Simple Token Test', es: 'Prueba simple de token', fr: 'Test simple du jeton')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _clearBrowserCache,
                      icon: const Icon(Icons.clear_all),
                      label: Text(_tr(en: 'Clear Browser Cache', es: 'Limpiar cache del navegador', fr: 'Vider le cache du navigateur')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _forceNewToken,
                      icon: const Icon(Icons.refresh),
                      label: Text(_tr(en: 'Force New Token', es: 'Forzar nuevo token', fr: 'Forcer un nouveau jeton')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testToken0,
                      icon: const Icon(Icons.numbers),
                      label: Text(_tr(en: 'Test Token 0', es: 'Probar token 0', fr: 'Tester le jeton 0')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _testToken1,
                      icon: const Icon(Icons.numbers),
                      label: Text(_tr(en: 'Test Token 1', es: 'Probar token 1', fr: 'Tester le jeton 1')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendSafariNotification,
                      icon: const Icon(Icons.apple),
                      label: Text(_tr(en: 'Send Safari Notification', es: 'Enviar notificacion Safari', fr: 'Envoyer une notification Safari')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendAndVerifyNotification,
                      icon: const Icon(Icons.notifications_active),
                      label: Text(_tr(en: 'Send & Verify Notification', es: 'Enviar y verificar notificacion', fr: 'Envoyer et verifier la notification')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendWebPushTest,
                      icon: const Icon(Icons.cloud_upload),
                      label: Text(_tr(en: 'Send Real Push Notification', es: 'Enviar notificacion push real', fr: 'Envoyer une vraie notification push')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Instructions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tr(
                              en: 'How to Test Push Notifications',
                              es: 'Como probar notificaciones push',
                              fr: 'Comment tester les notifications push',
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _tr(
                              en: '1. Make sure you\'re logged in to your account\n'
                                  '2. Grant notification permissions when prompted\n'
                                  '3. Check that all permissions are granted (green checkmarks)\n'
                                  '4. Note your FCM token (this should be generated)\n'
                                  '5. For mobile Safari: Add this page to your home screen\n'
                                  '6. Test by sending a notification (requires backend setup)',
                              es: '1. Asegurate de haber iniciado sesion en tu cuenta\n'
                                  '2. Otorga permisos de notificacion cuando se soliciten\n'
                                  '3. Verifica que todos los permisos esten concedidos (checks verdes)\n'
                                  '4. Anota tu token FCM (debe generarse)\n'
                                  '5. En Safari movil: agrega esta pagina a la pantalla de inicio\n'
                                  '6. Prueba enviando una notificacion (requiere backend configurado)',
                              fr: '1. Verifiez que vous etes connecte a votre compte\n'
                                  '2. Accordez les autorisations de notification lorsque demande\n'
                                  '3. Verifiez que toutes les autorisations sont accordees (checks verts)\n'
                                  '4. Notez votre jeton FCM (il doit etre genere)\n'
                                  '5. Pour Safari mobile : ajoutez cette page a l ecran d accueil\n'
                                  '6. Testez en envoyant une notification (backend requis)',
                            ),
                            style: TextStyle(height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tr(en: 'FCM Token Not Working?', es: 'El token FCM no funciona?', fr: 'Le jeton FCM ne fonctionne pas ?'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _tr(
                                    en: 'For real push notifications, you need:\n'
                                        '1. VAPID key (already configured) ✅\n'
                                        '2. Firebase Server Key:\n'
                                        '   • Go to Firebase Console → Project Settings\n'
                                        '   • Click "Cloud Messaging" tab\n'
                                        '   • Find "Server key" section\n'
                                        '   • Copy the server key\n'
                                        '   • Update the app code with your server key',
                                    es: 'Para notificaciones push reales, necesitas:\n'
                                        '1. Clave VAPID (ya configurada) ✅\n'
                                        '2. Clave del servidor de Firebase:\n'
                                        '   • Ve a Firebase Console → Configuracion del proyecto\n'
                                        '   • Abre la pestana "Cloud Messaging"\n'
                                        '   • Busca la seccion "Server key"\n'
                                        '   • Copia la clave del servidor\n'
                                        '   • Actualiza el codigo de la app con esa clave',
                                    fr: 'Pour de vraies notifications push, vous avez besoin de :\n'
                                        '1. Cle VAPID (deja configuree) ✅\n'
                                        '2. Cle serveur Firebase :\n'
                                        '   • Allez dans Firebase Console → Parametres du projet\n'
                                        '   • Ouvrez l onglet "Cloud Messaging"\n'
                                        '   • Trouvez la section "Server key"\n'
                                        '   • Copiez la cle serveur\n'
                                        '   • Mettez a jour le code de l app avec cette cle',
                                  ),
                                  style: TextStyle(height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tr(en: 'Mobile Safari Tips:', es: 'Consejos para Safari movil:', fr: 'Conseils Safari mobile :'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _tr(
                                    en: '• Notifications work best when the app is added to home screen\n'
                                        '• Make sure Safari notifications are enabled in Settings\n'
                                        '• Test with the app in background, not just foreground',
                                    es: '• Las notificaciones funcionan mejor cuando agregas la app a inicio\n'
                                        '• Asegurate de activar notificaciones de Safari en Configuracion\n'
                                        '• Prueba con la app en segundo plano, no solo en primer plano',
                                    fr: '• Les notifications marchent mieux si l app est sur l ecran d accueil\n'
                                        '• Verifiez que les notifications Safari sont activees dans Reglages\n'
                                        '• Testez avec l app en arriere-plan, pas seulement au premier plan',
                                  ),
                                  style: TextStyle(height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
