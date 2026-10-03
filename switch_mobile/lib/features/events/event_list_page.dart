import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'event_controller.dart';

class EventListPage extends StatefulWidget {
  final int switchId;

  const EventListPage({super.key, required this.switchId});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventController>().fetchEvents(widget.switchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventController = context.watch<EventController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log History Switch'),
      ),
      body: RefreshIndicator(
        onRefresh: () => eventController.fetchEvents(widget.switchId),
        child: eventController.isLoading
            ? const Center(child: CircularProgressIndicator())
            : eventController.events.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Center(
                        child: Text(
                          'Belum ada riwayat aktivitas.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: eventController.events.length,
                    itemBuilder: (context, index) {
                      final item = eventController.events[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            item.eventType.contains('CHECKIN')
                                ? Icons.check_circle
                                : item.eventType.contains('ARM')
                                    ? Icons.power_settings_new
                                    : Icons.notifications,
                            color: Colors.deepOrange,
                          ),
                          title: Text(
                            item.eventType,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.description ?? ''}\n${item.createdAt ?? ''}',
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
