import 'dart:async';

import 'package:campus_navigator/api/api_services.dart';
import 'package:campus_navigator/api/saved_places.dart';
import 'package:campus_navigator/api/storage.dart';
import 'package:campus_navigator/settings/app_settings_controller.dart';
import 'package:campus_navigator/settings/app_settings_scope.dart';
import 'package:campus_navigator/settings/cache_maintenance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen(
      {super.key, this.places, CacheMaintenance? cacheMaintenance})
      : _cacheMaintenance = cacheMaintenance;

  final PlaceStore? places;
  final CacheMaintenance? _cacheMaintenance;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final CacheMaintenance _cacheMaintenance =
      widget._cacheMaintenance ?? CacheMaintenance();
  AppSettingsController? _localSettings;

  bool _tudSelected = true;
  bool _passwordInvisible = true;
  bool _loading = true;
  bool _credentialsLoadFailed = false;
  bool _cacheSizeLoaded = false;
  bool _clearingCache = false;
  bool _clearingHistory = false;
  CacheDuration _cacheDuration = CacheDuration.day;
  PrefetchingLevel _prefetchingLevel = PrefetchingLevel.firstResult;
  double _qualityLevel = 4;
  int? _cacheBytes;
  String _appVersion = '—';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadAppVersion();
    _refreshCacheSize();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _localSettings?.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final (
      usernameResult,
      passwordResult,
      universityResult,
      cacheDurationResult,
      prefetchingResult,
      qualityResult,
    ) = await (
      _readPreferenceSafely(APIServices.Shared.storage.getUsername),
      _readPreferenceSafely(APIServices.Shared.storage.getPassword),
      _readPreferenceSafely(APIServices.Shared.storage.getUniversityStrict),
      _readPreferenceSafely(APIServices.Shared.storage.getCacheDuration),
      _readPreferenceSafely(APIServices.Shared.storage.getPrefetchingLevel),
      _readPreferenceSafely(APIServices.Shared.storage.getQualityLevel),
    ).wait;

    if (!mounted) return;
    setState(() {
      _usernameController.text = usernameResult.$1 ?? '';
      _passwordController.text = passwordResult.$1 ?? '';
      _credentialsLoadFailed =
          usernameResult.$2 || passwordResult.$2 || universityResult.$2;
      _tudSelected =
          (universityResult.$1 ?? UserUniversity.TUD) == UserUniversity.TUD;
      _cacheDuration = cacheDurationResult.$1 ?? CacheDuration.day;
      _prefetchingLevel = prefetchingResult.$1 ?? PrefetchingLevel.firstResult;
      _qualityLevel = (qualityResult.$1 ?? 4).clamp(1, 4).toDouble();
      _loading = false;
    });
  }

  Future<(T?, bool)> _readPreferenceSafely<T>(Future<T> Function() read) async {
    try {
      return (await read(), false);
    } catch (_) {
      return (null, true);
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      // Package metadata may be unavailable in desktop previews and tests.
    }
  }

  Future<void> _refreshCacheSize() async {
    final bytes = await _cacheMaintenance.estimateBytes();
    if (!mounted) return;
    setState(() {
      _cacheBytes = bytes;
      _cacheSizeLoaded = true;
    });
  }

  Future<void> _persist(Future<void> Function() save) async {
    try {
      await save();
    } catch (_) {
      if (mounted) {
        _showMessage(_settingsText(AppLocalizations.of(context)!,
            'settingsSaveFailure', 'The setting could not be saved.'));
      }
    }
  }

  Future<bool> _confirm(
      {required String title, required String content}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_settingsText(
                AppLocalizations.of(context)!, 'settingsCancel', 'Cancel')),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_settingsText(
                AppLocalizations.of(context)!, 'settingsConfirm', 'Confirm')),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _clearCache() async {
    if (!await _confirm(
      title: _settingsText(AppLocalizations.of(context)!, 'settingsClearCache',
          'Clear map and search cache?'),
      content: _settingsText(
          AppLocalizations.of(context)!,
          'settingsClearCacheDescription',
          'Temporary map tiles and campus data will be downloaded again when needed. Favorites, history and settings are kept.'),
    )) {
      return;
    }
    setState(() => _clearingCache = true);
    var succeeded = false;
    try {
      await _cacheMaintenance.clear();
      succeeded = true;
    } catch (_) {
      succeeded = false;
    } finally {
      if (mounted) setState(() => _clearingCache = false);
    }
    await _refreshCacheSize();
    if (mounted) {
      _showMessage(_settingsText(
          AppLocalizations.of(context)!,
          succeeded
              ? 'settingsCacheActionSuccess'
              : 'settingsCacheActionFailure',
          succeeded
              ? 'Temporary cache cleared.'
              : 'Some temporary cache data could not be cleared.'));
    }
  }

  Future<void> _clearHistory() async {
    final places = widget.places;
    if (places == null) return;
    if (!await _confirm(
      title: _settingsText(AppLocalizations.of(context)!,
          'settingsClearHistory', 'Clear search history?'),
      content: _settingsText(
          AppLocalizations.of(context)!,
          'settingsClearHistoryDescription',
          'This removes recently viewed rooms. Saved favorites are kept.'),
    )) {
      return;
    }
    setState(() => _clearingHistory = true);
    var cleared = false;
    try {
      cleared = await places.clearHistory();
    } catch (_) {
      cleared = false;
    } finally {
      if (mounted) setState(() => _clearingHistory = false);
    }
    if (mounted) {
      _showMessage(_settingsText(
          AppLocalizations.of(context)!,
          cleared
              ? 'settingsHistoryActionSuccess'
              : 'settingsHistoryActionFailure',
          cleared
              ? 'Search history cleared.'
              : 'Search history could not be cleared.'));
    }
  }

  Future<void> _restoreDefaults(AppSettingsController settings) async {
    if (!await _confirm(
      title: _settingsText(AppLocalizations.of(context)!,
          'settingsRestoreDefaults', 'Restore appearance defaults?'),
      content: _settingsText(
          AppLocalizations.of(context)!,
          'settingsRestoreDefaultsDescription',
          'Use the device theme and language, automatic campus map styling, and Campus Identity option A.'),
    )) {
      return;
    }
    await _persist(settings.restoreAppearanceDefaults);
  }

  Future<void> _saveCredentials() async {
    if (_credentialsLoadFailed) return;
    try {
      await APIServices.Shared.storage.editUsername(_usernameController.text);
      await APIServices.Shared.storage.editpassword(_passwordController.text);
      await APIServices.Shared.storage.editUniversity(
          _tudSelected ? UserUniversity.TUD : UserUniversity.HTW);
    } catch (_) {
      if (mounted) {
        _showMessage(_settingsText(AppLocalizations.of(context)!,
            'settingsSaveFailure', 'The setting could not be saved.'));
      }
    }
  }

  Future<void> _deleteCredentials() async {
    try {
      await APIServices.Shared.storage.editUsername('');
      await APIServices.Shared.storage.editpassword('');
      await APIServices.Shared.storage.editUniversity(UserUniversity.TUD);
      if (!mounted) return;
      setState(() {
        _usernameController.clear();
        _passwordController.clear();
        _tudSelected = true;
      });
    } catch (_) {
      if (mounted) {
        _showMessage(_settingsText(AppLocalizations.of(context)!,
            'settingsSaveFailure', 'The setting could not be saved.'));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openRepository() async {
    final uri = Uri.parse('https://github.com/Infinizius/campus-navigator');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('No application can open the repository link.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage(_settingsText(AppLocalizations.of(context)!,
            'settingsRepository', 'Campus Navigator on GitHub'));
      }
    }
  }

  String _formatBytes(BuildContext context) {
    if (!_cacheSizeLoaded || _cacheBytes == null) {
      return _settingsText(AppLocalizations.of(context)!,
          'settingsCacheUnavailable', 'Not available');
    }
    final l10n = AppLocalizations.of(context)!;
    if (_cacheBytes! < 1024) {
      return '${_cacheBytes!} ${_settingsText(l10n, 'settingsCacheBytesUnit', 'B')}';
    }
    if (_cacheBytes! < 1024 * 1024) {
      return '${(_cacheBytes! / 1024).toStringAsFixed(1)} ${_settingsText(l10n, 'settingsCacheKilobytesUnit', 'KB')}';
    }
    return '${(_cacheBytes! / (1024 * 1024)).toStringAsFixed(1)} ${_settingsText(l10n, 'settingsCacheMegabytesUnit', 'MB')}';
  }

  @override
  Widget build(BuildContext context) {
    final sharedSettings = AppSettingsScope.maybeOf(context);
    if (sharedSettings != null) {
      return _buildScreen(context, sharedSettings);
    }

    final localSettings = _localSettings ??= AppSettingsController();
    if (!localSettings.loaded) unawaited(localSettings.load());
    return AnimatedBuilder(
      animation: localSettings,
      builder: (context, _) => _buildScreen(context, localSettings),
    );
  }

  Widget _buildScreen(BuildContext context, AppSettingsController settings) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreen_Title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          _sectionHeading(
              _settingsText(l10n, 'settingsAppearanceTitle', 'Appearance')),
          _settingsDropdown<String>(
            label: _settingsText(l10n, 'settingsThemeTitle', 'App theme'),
            value: settings.themeMode.name,
            items: [
              DropdownMenuItem(
                  value: ThemeMode.system.name,
                  child: Text(_settingsText(
                      l10n, 'settingsThemeSystem', 'System default'))),
              DropdownMenuItem(
                  value: ThemeMode.light.name,
                  child:
                      Text(_settingsText(l10n, 'settingsThemeLight', 'Light'))),
              DropdownMenuItem(
                  value: ThemeMode.dark.name,
                  child:
                      Text(_settingsText(l10n, 'settingsThemeDark', 'Dark'))),
            ],
            onChanged: (value) {
              if (value == null) return;
              final mode = ThemeMode.values.byName(value);
              _persist(() => settings.setThemeMode(mode));
            },
          ),
          const SizedBox(height: 12),
          _settingsDropdown<String>(
            label: _settingsText(l10n, 'settingsLanguageTitle', 'App language'),
            value: settings.locale == null
                ? 'system'
                : AppLanguage.fromLocale(settings.locale!)?.storageTag ??
                    'system',
            items: [
              DropdownMenuItem(
                  value: 'system',
                  child: Text(_settingsText(
                      l10n, 'settingsLanguageSystem', 'Device language'))),
              ...AppLanguage.values.map((language) => DropdownMenuItem(
                    value: language.storageTag,
                    child: Text(language.nativeName),
                  )),
            ],
            onChanged: (value) {
              if (value == null) return;
              final locale = value == 'system'
                  ? null
                  : AppLanguage.values
                      .firstWhere((language) => language.storageTag == value)
                      .locale;
              _persist(() => settings.setLocale(locale));
            },
          ),
          const SizedBox(height: 12),
          _settingsDropdown<CampusMapThemeMode>(
            label: _settingsText(l10n, 'settingsMapThemeTitle', 'Campus map'),
            value: settings.campusMapThemeMode,
            items: [
              DropdownMenuItem(
                  value: CampusMapThemeMode.automatic,
                  child: Text(_settingsText(
                      l10n, 'settingsMapThemeAutomatic', 'Automatic'))),
              DropdownMenuItem(
                  value: CampusMapThemeMode.light,
                  child: Text(_settingsText(
                      l10n, 'settingsMapThemeLight', 'Light map'))),
              DropdownMenuItem(
                  value: CampusMapThemeMode.dark,
                  child: Text(
                      _settingsText(l10n, 'settingsMapThemeDark', 'Dark map'))),
            ],
            onChanged: (value) {
              if (value != null) {
                _persist(() => settings.setCampusMapThemeMode(value));
              }
            },
          ),
          const SizedBox(height: 12),
          _settingsDropdown<AppCampusIdentityStyle>(
            label: _settingsText(
                l10n, 'settingsIdentityStyleTitle', 'Campus identity'),
            value: settings.campusIdentityStyle,
            items: [
              DropdownMenuItem(
                value: AppCampusIdentityStyle.academic,
                child: Text(_settingsText(
                  l10n,
                  'settingsIdentityAcademic',
                  'Option A · Modern academic',
                )),
              ),
              DropdownMenuItem(
                value: AppCampusIdentityStyle.wayfinding,
                child: Text(_settingsText(
                  l10n,
                  'settingsIdentityWayfinding',
                  'Option B · Campus wayfinding',
                )),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _persist(() => settings.setCampusIdentityStyle(value));
              }
            },
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _restoreDefaults(settings),
              icon: const Icon(Icons.restart_alt),
              label: Text(_settingsText(
                  l10n, 'settingsRestoreDefaults', 'Restore defaults')),
            ),
          ),
          _sectionHeading(l10n.settingsScreen_LoginTitle),
          if (_loading)
            const LinearProgressIndicator(minHeight: 2)
          else ...[
            if (_credentialsLoadFailed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _settingsText(
                    l10n,
                    'settingsCredentialsLoadFailure',
                    'Saved login settings could not be loaded. Editing is paused.',
                  ),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextField(
              enabled: !_credentialsLoadFailed,
              controller: _usernameController,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.settingsScreen_LoginUsername,
                hintText: l10n.settingsScreen_LoginUsernameDescription,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              enabled: !_credentialsLoadFailed,
              controller: _passwordController,
              autocorrect: false,
              obscureText: _passwordInvisible,
              decoration: InputDecoration(
                labelText: l10n.settingsScreen_LoginPassword,
                hintText: l10n.settingsScreen_LoginPasswordHint,
                suffixIcon: IconButton(
                  tooltip: _settingsText(
                      l10n,
                      _passwordInvisible
                          ? 'settingsShowPassword'
                          : 'settingsHidePassword',
                      _passwordInvisible ? 'Show password' : 'Hide password'),
                  icon: Icon(_passwordInvisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _passwordInvisible = !_passwordInvisible),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text(l10n.settingsScreen_University)),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: true, label: Text('TUD')),
                    ButtonSegment(value: false, label: Text('HTW')),
                  ],
                  selected: {_tudSelected},
                  onSelectionChanged: _credentialsLoadFailed
                      ? null
                      : (selection) =>
                          setState(() => _tudSelected = selection.first),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _credentialsLoadFailed ? null : _saveCredentials,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(l10n.settingsScreen_LoginUpdate),
                ),
                TextButton.icon(
                  onPressed: () async {
                    if (await _confirm(
                      title: l10n.settingsScreen_LoginDelete,
                      content: l10n.settingsScreen_LoginDeleteDescription,
                    )) {
                      await _deleteCredentials();
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.settingsScreen_LoginDelete),
                ),
              ],
            ),
          ],
          _sectionHeading(
              _settingsText(l10n, 'settingsDataTitle', 'Data and cache')),
          _settingsDropdown<CacheDuration>(
            label: l10n.settingsScreen_cacheSectionTitle,
            value: _cacheDuration,
            items: [
              DropdownMenuItem(
                  value: CacheDuration.day,
                  child: Text(l10n.settingsScreen_optionDay)),
              DropdownMenuItem(
                  value: CacheDuration.week,
                  child: Text(l10n.settingsScreen_optionWeek)),
              DropdownMenuItem(
                  value: CacheDuration.month,
                  child: Text(l10n.settingsScreen_optionMonth)),
              DropdownMenuItem(
                  value: CacheDuration.year,
                  child: Text(l10n.settingsScreen_optionYear)),
            ],
            onChanged: (value) {
              if (value == null) return;
              _persist(() async {
                await APIServices.Shared.storage.setCacheDuration(value);
                if (mounted) setState(() => _cacheDuration = value);
              });
            },
          ),
          const SizedBox(height: 12),
          _settingsDropdown<PrefetchingLevel>(
            label: l10n.settingsScreen_PrefetchingTitle,
            items: [
              DropdownMenuItem(
                  value: PrefetchingLevel.none,
                  child: Text(l10n.settingsScreen_PrefetchingNone)),
              DropdownMenuItem(
                  value: PrefetchingLevel.firstResult,
                  child: Text(l10n.settingsScreen_PrefetchingFirst)),
              DropdownMenuItem(
                  value: PrefetchingLevel.allResults,
                  child: Text(l10n.settingsScreen_PrefetchingAll)),
            ],
            value: _prefetchingLevel,
            onChanged: (value) {
              if (value == null) return;
              _persist(() async {
                await APIServices.Shared.storage.setPrefetchingLevel(value);
                if (mounted) setState(() => _prefetchingLevel = value);
              });
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsScreen_QualityLevelTitle),
            subtitle: Text(l10n.settingsScreen_QualityLevelDescription),
            trailing: Text(_qualityLevel.round().toString(),
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Slider(
            value: _qualityLevel,
            min: 1,
            max: 4,
            divisions: 3,
            label: _qualityLevel.round().toString(),
            semanticFormatterCallback: (value) =>
                '${l10n.settingsScreen_QualityLevelTitle} ${value.round()}',
            onChanged: (value) => setState(() => _qualityLevel = value),
            onChangeEnd: (value) => _persist(() =>
                APIServices.Shared.storage.setQualityLevel(value.round())),
          ),
          _sectionHeading(
              _settingsText(l10n, 'settingsLocalDataTitle', 'Local data')),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _settingsText(l10n, 'settingsLocalDataDescription',
                  'Temporary map data can be cleared separately; favorites, history and personal settings are kept.'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.storage_outlined),
            title: Text(
                _settingsText(l10n, 'settingsCacheSize', 'Temporary cache')),
            subtitle: Text(_formatBytes(context)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_sweep_outlined),
            title:
                Text(_settingsText(l10n, 'settingsClearCache', 'Clear cache')),
            subtitle: Text(_settingsText(l10n, 'settingsClearCacheDescription',
                'Temporary map tiles and campus data are downloaded again when needed. Favorites and settings are kept.')),
            trailing: _clearingCache
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _clearingCache ? null : _clearCache,
          ),
          if (widget.places != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history),
              title: Text(_settingsText(
                  l10n, 'settingsClearHistory', 'Clear search history')),
              subtitle: Text(_settingsText(
                  l10n,
                  'settingsClearHistoryDescription',
                  'Recently viewed rooms are removed. Favorites are kept.')),
              trailing: _clearingHistory
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _clearingHistory ? null : _clearHistory,
            ),
          _sectionHeading(_settingsText(l10n, 'settingsAboutTitle', 'About')),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: Text(_settingsText(l10n, 'settingsVersion', 'Version')),
            subtitle: Text(_appVersion),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _settingsText(l10n, 'settingsUnofficialNotice',
                  'Unofficial community project; it is not supported or endorsed by TU Dresden.'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.map_outlined),
            title: Text(_settingsText(l10n, 'settingsSources', 'Data sources')),
            subtitle: Text(_settingsText(l10n, 'settingsDataSourcesDescription',
                'Campus building data and floor plans are provided by navigator.tu-dresden.de. Map tiles © OpenStreetMap contributors. Licensing of the original AKORA code and TU floor-plan data remains unclear.')),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.code),
            title: Text(
                _settingsText(l10n, 'settingsRepository', 'GitHub repository')),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: _openRepository,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(_settingsText(
                l10n, 'settingsLicenses', 'Open-source licenses')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Campus Navigator',
              applicationVersion: _appVersion,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _settingsDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) =>
      DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: items,
        onChanged: onChanged,
      );
}

/// Reads newly introduced ARB getters dynamically while this branch remains
/// independent from the UI branch that owns the generated ARB catalogs. Once
/// those catalogs are integrated, their strongly translated getters are used.
String _settingsText(
    AppLocalizations localizations, String key, String fallback) {
  final dynamic l10n = localizations;
  try {
    return switch (key) {
      'settingsAppearanceTitle' => l10n.settingsAppearanceTitle as String,
      'settingsThemeTitle' => l10n.settingsThemeTitle as String,
      'settingsThemeSystem' => l10n.settingsThemeSystem as String,
      'settingsThemeLight' => l10n.settingsThemeLight as String,
      'settingsThemeDark' => l10n.settingsThemeDark as String,
      'settingsLanguageTitle' => l10n.settingsLanguageTitle as String,
      'settingsLanguageSystem' => l10n.settingsLanguageSystem as String,
      'settingsMapThemeTitle' => l10n.settingsMapThemeTitle as String,
      'settingsMapThemeAutomatic' => l10n.settingsMapThemeAutomatic as String,
      'settingsMapThemeLight' => l10n.settingsMapThemeLight as String,
      'settingsMapThemeDark' => l10n.settingsMapThemeDark as String,
      'settingsIdentityStyleTitle' => l10n.settingsIdentityStyleTitle as String,
      'settingsIdentityAcademic' => l10n.settingsIdentityAcademic as String,
      'settingsIdentityWayfinding' => l10n.settingsIdentityWayfinding as String,
      'settingsDataTitle' => l10n.settingsDataTitle as String,
      'settingsCacheSize' => l10n.settingsCacheSize as String,
      'settingsCacheUnavailable' => l10n.settingsCacheUnavailable as String,
      'settingsClearCache' => l10n.settingsClearCache as String,
      'settingsClearCacheDescription' =>
        l10n.settingsClearCacheDescription as String,
      'settingsClearHistory' => l10n.settingsClearHistory as String,
      'settingsClearHistoryDescription' =>
        l10n.settingsClearHistoryDescription as String,
      'settingsCancel' => l10n.settingsCancel as String,
      'settingsConfirm' => l10n.settingsConfirm as String,
      'settingsAboutTitle' => l10n.settingsAboutTitle as String,
      'settingsVersion' => l10n.settingsVersion as String,
      'settingsUnofficialNotice' => l10n.settingsUnofficialNotice as String,
      'settingsSources' => l10n.settingsSources as String,
      'settingsRepository' => l10n.settingsRepository as String,
      'settingsLicenses' => l10n.settingsLicenses as String,
      'settingsRestoreDefaults' => l10n.settingsRestoreDefaults as String,
      'settingsRestoreDefaultsDescription' =>
        l10n.settingsRestoreDefaultsDescription as String,
      'settingsCacheActionSuccess' => l10n.settingsCacheActionSuccess as String,
      'settingsCacheActionFailure' => l10n.settingsCacheActionFailure as String,
      'settingsHistoryActionSuccess' =>
        l10n.settingsHistoryActionSuccess as String,
      'settingsHistoryActionFailure' =>
        l10n.settingsHistoryActionFailure as String,
      'settingsSaveFailure' => l10n.settingsSaveFailure as String,
      'settingsCacheBytesUnit' => l10n.settingsCacheBytesUnit as String,
      'settingsCacheKilobytesUnit' => l10n.settingsCacheKilobytesUnit as String,
      'settingsCacheMegabytesUnit' => l10n.settingsCacheMegabytesUnit as String,
      'settingsLocalDataTitle' => l10n.settingsLocalDataTitle as String,
      'settingsLocalDataDescription' =>
        l10n.settingsLocalDataDescription as String,
      'settingsDataSourcesDescription' =>
        l10n.settingsDataSourcesDescription as String,
      'settingsCredentialsLoadFailure' =>
        l10n.settingsCredentialsLoadFailure as String,
      'settingsShowPassword' => l10n.settingsShowPassword as String,
      'settingsHidePassword' => l10n.settingsHidePassword as String,
      _ => fallback,
    };
  } on NoSuchMethodError {
    return fallback;
  }
}
