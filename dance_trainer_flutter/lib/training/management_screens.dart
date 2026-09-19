import 'dart:convert';
import 'dart:io';
import 'package:dance_domain/dance_domain.dart';
import 'package:dance_trainer_client/dance_trainer_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'repository.dart';
import 'progress.dart';
import 'screens.dart' show readableError, ResultScreen;

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.repository});
  final TrainingRepository repository;
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _attempts = <TrainingAttempt>[];
  List<Map<String, Object?>> _local = [];
  bool _loading = false, _more = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Local completed results remain reachable even when the server is offline.
      if (!kIsWeb && Platform.isAndroid) {
        final rows = await widget.repository.localRuns();
        if (mounted) setState(() => _local = rows);
      }
      final page = await widget.repository.client.training.history(
        offset: 0,
        beforeId: refresh || _attempts.isEmpty ? null : _attempts.last.id,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) _attempts.clear();
        _attempts.addAll(page);
        _more = page.length == 30;
      });
    } catch (e) {
      if (mounted) setState(() => _error = readableError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(TrainingAttempt attempt) async {
    try {
      final catalog = await widget.repository.client.catalog.list();
      final entry = catalog
          .where(
            (e) =>
                e.routineId == attempt.routineId &&
                e.version == attempt.contentVersion,
          )
          .firstOrNull;
      if (!mounted) return;
      if (entry == null) {
        setState(
          () => _error =
              'This result is saved, but its routine version is no longer in the catalog.',
        );
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            repository: widget.repository,
            entry: entry,
            attempt: attempt,
            result: jsonObject(jsonDecode(attempt.resultJson!)),
            pending: false,
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = readableError(e));
    }
  }

  String _comparison(int index) {
    final current = _attempts[index];
    for (final prior in _attempts.skip(index + 1)) {
      final delta = scoreChange(current, prior);
      if (delta != null) {
        final coverage = finiteNumber(
          jsonObject(jsonDecode(prior.resultJson!))['coverage'],
        );
        return '\n${delta >= 0 ? '+' : ''}$delta points vs previous comparable attempt, prior tracking ${(coverage * 100).round()}%';
      }
    }
    return '\nNo earlier comparable result in loaded history.';
  }

  Future<void> _discard(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this local run?'),
        content: const Text(
          'Unsynced evidence will be removed from this device. Any result already saved to your account remains.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep run'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.discardLocalRun(id);
      await _load(refresh: true);
    } catch (e) {
      if (mounted) setState(() => _error = readableError(e));
    }
  }

  Future<void> _openLocal(Map<String, Object?> row) async {
    try {
      if (row['entry'] == null) {
        throw StateError(
          'This older run needs a connection to restore its result.',
        );
      }
      final result = await widget.repository.provisionalResult(
        row['id'] as int,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            repository: widget.repository,
            entry: TrainingCatalogEntry.fromJson(
              jsonObject(jsonDecode(row['entry'] as String)),
            ),
            attempt: TrainingAttempt.fromJson(
              jsonObject(jsonDecode(row['attempt'] as String)),
            ),
            result: result,
            pending: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = readableError(e));
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => _load(refresh: true),
    child: ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Text(
          'Your progress',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const Text(
          'Comparisons use matching routine, section, content, model and scoring versions at the same speed.',
        ),
        for (final row in _local)
          Card(
            child: ListTile(
              title: Text(
                TrainingAttempt.fromJson(
                  jsonObject(jsonDecode(row['attempt'] as String)),
                ).routineId,
              ),
              subtitle: Text(
                row['endMs'] == null
                    ? 'Interrupted before completion. Start a new run to record a complete result.'
                    : row['error'] as String? ??
                          'Completed on this device. Waiting to sync.',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (row['endMs'] != null)
                    IconButton(
                      tooltip: 'Sync this run',
                      icon: const Icon(Icons.sync),
                      onPressed: () async {
                        try {
                          await widget.repository.sync(row['id'] as int);
                          await _load(refresh: true);
                        } catch (e) {
                          if (mounted) {
                            setState(() => _error = readableError(e));
                          }
                        }
                      },
                    ),
                  IconButton(
                    tooltip: 'Discard local run',
                    onPressed: () => _discard(row['id'] as int),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              onTap: row['endMs'] == null ? null : () => _openLocal(row),
            ),
          ),
        if (_error != null) Text(_error!),
        if (_error != null)
          TextButton(
            onPressed: _loading ? null : () => _load(refresh: true),
            child: const Text('Retry'),
          ),
        if (!_loading && _attempts.isEmpty && _local.isEmpty && _error == null)
          const Text('Your completed routines and drills will appear here.'),
        for (var i = 0; i < _attempts.length; i++)
          Card(
            child: ListTile(
              title: Text(_attempts[i].routineId),
              subtitle: Text(
                '${_attempts[i].mode} · ${_attempts[i].createdAt.toLocal().toString().split('.').first}\nTracking ${(finiteNumber(jsonObject(jsonDecode(_attempts[i].resultJson!))['coverage']) * 100).round()}%${_comparison(i)}',
              ),
              trailing: Text(
                jsonObject(
                          jsonDecode(_attempts[i].resultJson!),
                        )['judgmentAvailable'] ==
                        true
                    ? '${jsonObject(jsonDecode(_attempts[i].resultJson!))['totalScore']}'
                    : 'Not enough\ntracking',
              ),
              onTap: () => _open(_attempts[i]),
            ),
          ),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_more && _attempts.isNotEmpty)
          TextButton(
            onPressed: _loading ? null : _load,
            child: const Text('Load older attempts'),
          ),
      ],
    ),
  );
}

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key, required this.repository});
  final TrainingRepository repository;
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<CachedAsset> _assets = [];
  List<TrainingCatalogEntry> _catalog = [];
  bool _busy = false;
  double? _progress;
  String? _message;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final assets = await widget.repository.cachedAssets();
      if (mounted) setState(() => _assets = assets);
      final catalog = await widget.repository.client.catalog.list();
      if (mounted) setState(() => _catalog = catalog);
    } catch (e) {
      if (mounted) setState(() => _message = readableError(e));
    }
  }

  Future<void> _download(String path, String hash) async {
    setState(() {
      _busy = true;
      _progress = null;
      _message = null;
    });
    try {
      await widget.repository.download(
        path,
        hash,
        progress: (p) {
          if (mounted) setState(() => _progress = p == 0 ? null : p);
        },
      );
      await _load();
    } catch (e) {
      if (mounted) setState(() => _message = readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _name(CachedAsset asset) {
    final name = asset.file.uri.pathSegments.last;
    if (name.startsWith(poseModelHash)) {
      return 'Pose model${name.endsWith('.part') ? ' · incomplete' : ''}';
    }
    final entry = _catalog
        .where((e) => name.startsWith(e.mediaSha256))
        .firstOrNull;
    return '${entry?.title ?? 'Archived routine video'}${name.endsWith('.part') ? ' · incomplete' : ''}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Downloads')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '${(_assets.fold<int>(0, (sum, a) => sum + a.bytes) / (1024 * 1024)).toStringAsFixed(1)} MB on this device',
        ),
        const Text(
          'Removing a video or model keeps your saved results. Downloads are verified before use.',
        ),
        if (_message != null) Text(_message!),
        if (_busy) LinearProgressIndicator(value: _progress),
        for (final asset in _assets)
          ListTile(
            title: Text(_name(asset)),
            subtitle: Text(
              '${(asset.bytes / (1024 * 1024)).toStringAsFixed(1)} MB',
            ),
            trailing: IconButton(
              tooltip: 'Remove download',
              onPressed: _busy
                  ? null
                  : () async {
                      try {
                        await widget.repository.removeAsset(asset);
                        await _load();
                      } catch (e) {
                        if (mounted) {
                          setState(() => _message = readableError(e));
                        }
                      }
                    },
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        const Divider(),
        for (final entry in _catalog)
          ListTile(
            title: Text(entry.title),
            trailing: TextButton(
              onPressed: _busy
                  ? null
                  : () => _download(entry.mediaPath, entry.mediaSha256),
              child: const Text('Download / verify'),
            ),
          ),
        TextButton(
          onPressed: _busy
              ? null
              : () => _download(
                  '/content/models/yolov8n-pose_xnnpack.pte',
                  poseModelHash,
                ),
          child: const Text('Download / verify pose model'),
        ),
        TextButton(
          onPressed: _busy ? null : _load,
          child: const Text('Refresh'),
        ),
      ],
    ),
  );
}
