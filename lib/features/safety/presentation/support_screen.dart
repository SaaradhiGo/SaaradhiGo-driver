import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../trip/presentation/trip_controller.dart';
import '../domain/safety_repository.dart';
import 'safety_controller.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(supportTicketsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newTicket(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New ticket'),
      ),
      body: ticketsAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(supportTicketsProvider),
        ),
        data: (tickets) => tickets.isEmpty
            ? const EmptyView(
                message:
                    'No support tickets. Raise one if something goes wrong on '
                    'a trip.',
                icon: Icons.support_agent_outlined,
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(supportTicketsProvider);
                  await ref.read(supportTicketsProvider.future);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          ticket.subject,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(Fmt.relative(ticket.createdAt)),
                        trailing: StatusChip(
                          label: Fmt.titleCase(ticket.state),
                          color:
                              ticket.isOpen ? AppTheme.warning : AppTheme.brand,
                        ),
                        onTap: () => _openThread(context, ref, ticket.id),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _newTicket(BuildContext context, WidgetRef ref) async {
    final tripId = ref.read(tripControllerProvider).trip?.id;
    final result = await showModalBottomSheet<({String subject, String body})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NewTicketSheet(),
    );
    if (result == null) return;

    try {
      await ref.read(safetyRepositoryProvider).createTicket(
            subject: result.subject,
            body: result.body,
            category: 'driver',
            tripId: tripId,
          );
      ref.invalidate(supportTicketsProvider);
      if (context.mounted) {
        showInfoSnack(context, 'Ticket raised. Support will reply here.');
      }
    } on Object catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _openThread(
    BuildContext context,
    WidgetRef ref,
    int ticketId,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ThreadSheet(ticketId: ticketId),
    );
  }
}

class _NewTicketSheet extends StatefulWidget {
  const _NewTicketSheet();

  @override
  State<_NewTicketSheet> createState() => _NewTicketSheetState();
}

class _NewTicketSheetState extends State<_NewTicketSheet> {
  final _subject = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What happened?',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Subject'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Describe the issue',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              final subject = _subject.text.trim();
              final body = _body.text.trim();
              if (subject.isEmpty || body.isEmpty) return;
              Navigator.of(context).pop((subject: subject, body: body));
            },
            child: const Text('Send to support'),
          ),
        ],
      ),
    );
  }
}

class _ThreadSheet extends ConsumerWidget {
  const _ThreadSheet({required this.ticketId});

  final int ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(supportTicketProvider(ticketId));

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: ticketAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(supportTicketProvider(ticketId)),
        ),
        data: (ticket) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                ticket.subject,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ticket.messages.isEmpty
                  ? const EmptyView(message: 'No replies yet.')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: ticket.messages.length,
                      itemBuilder: (context, index) =>
                          _MessageBubble(message: ticket.messages[index]),
                    ),
            ),
            _Composer(ticketId: ticketId),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isStaff = message.isStaff;

    return Align(
      alignment: isStaff ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isStaff ? scheme.surfaceContainerHighest : scheme.primaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.body),
            const SizedBox(height: 4),
            Text(
              '${isStaff ? 'Support' : 'You'} · ${Fmt.relative(message.createdAt)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends ConsumerStatefulWidget {
  const _Composer({required this.ticketId});

  final int ticketId;

  @override
  ConsumerState<_Composer> createState() => _ComposerState();
}

class _ComposerState extends ConsumerState<_Composer> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(safetyRepositoryProvider)
          .addMessage(ticketId: widget.ticketId, body: body);
      _controller.clear();
      ref.invalidate(supportTicketProvider(widget.ticketId));
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Write a reply…'),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
