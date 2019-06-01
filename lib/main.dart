import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// 1 - main.dart é o ponto de entrada de qualquer app .dart
// 2 - O arquivo precisa ter uma função main também
void main() => runApp(FrontEndBrVagasApp());

class FrontEndBrVagasApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: JobsListRoute());
  }
}

class JobsListRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.blueGrey,
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: Colors.white,
              pinned: true,
              expandedHeight: 250.0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: SizedBox.expand(
                  child: Image.network(
                    'https://avatars1.githubusercontent.com/u/16963863?v=4',
                    alignment: Alignment.bottomCenter,
                    scale: 4,
                  ),
                ),
              ),
            ),
            SliverFixedExtentList(
              itemExtent: 50,
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Container(
                    alignment: Alignment.center,
                    color: Colors.lightBlue[100 * (index % 9)],
                    child: Text('list item $index'),
                  );
                },
                childCount: 50,
              ),
            )
            // SliverFixedExtentList(
            //   itemExtent: 6.0,
            //   delegate: SliverChildBuilderDelegate(
            //     (BuildContext context, int index) {
            //       return Container(
            //         alignment: Alignment.center,
            //         color: Colors.lightBlue[100 * (index % 9)],
            //         child: Text('list item $index'),
            //       );
            //     },
            //   ),
            // ),
          ],
        ));
    //   body: Column(
    //   children: <Widget>[
    //     Container(
    //       child: Image.network(
    //           'https://avatars1.githubusercontent.com/u/16963863?v=4'),
    //     ),
    //     Container(child: JobsContainer()),
    //   ],
    // ));
  }
}

class JobsContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: fetchJobs(),
        builder: (BuildContext context, AsyncSnapshot<Iterable<Job>> snapshot) {
          if (snapshot.hasError) {
            return Text('Deu ruim');
          }
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

          return ListView.builder(
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                final job = snapshot.data.elementAt(index);
                return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => JobDescriptionRoute(
                                  jobId: job.id,
                                )),
                      );
                    },
                    child: JobCard(
                      title: job.title,
                    ));
              });
        });
  }
}

class JobCard extends StatelessWidget {
  final String title;
  final String description;

  JobCard({@required this.title, this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Column(
      children: <Widget>[
        ListTile(title: Text(this.title)),
        JobCardDescription(description: this.description),
      ],
    ));
  }
}

class JobCardDescription extends StatelessWidget {
  final String description;
  JobCardDescription({this.description});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    if (this.description != null) {
      return Text(this.description);
    }
    return Text('');
  }
}

class Job {
  final String title;
  final String description;
  final int id;

  Job({@required this.title, @required this.id, this.description});

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      title: json['title'],
      id: json['number'],
      description: json['body'],
    );
  }
}

Future<Iterable<Job>> fetchJobs() async {
  try {
    final response = await http
        .get('https://api.github.com/repos/frontendbr/vagas/issues', headers: {
      HttpHeaders.authorizationHeader:
          "token fb272885581671ed2beba9ac76207c124a1e7da2"
    });
    final jsonData = json.decode(response.body);

    if (response.statusCode == 200) {
      // If the call to the server was successful, parse the JSON
      return (jsonData as List)
          .map((data) => Job(title: data['title'], id: data['number']))
          .toList();
    }

    throw Exception('Failed to load Jobs');
  } catch (error) {
    throw Exception(error);
  }
}

Future<Job> fetchJobById(int id) async {
  try {
    final response = await http
        .get('https://api.github.com/repos/frontendbr/vagas/issues/$id');
    final jsonData = json.decode(response.body);

    if (response.statusCode == 200) {
      // If the call to the server was successful, parse the JSON
      return Job(
          title: jsonData['title'],
          id: jsonData['id'],
          description: jsonData['body']);
    }

    throw Exception('Failed to load Jobs');
  } catch (error) {
    throw Exception(error);
  }
}

// ====================================================

class JobDescriptionRoute extends StatelessWidget {
  final int jobId;

  JobDescriptionRoute({@required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Vaga #$jobId"),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.thumb_up),
          backgroundColor: Colors.pink,
          onPressed: () {
            _launchURL(
                'https://github.com/frontendbr/vagas/issues/$jobId#bottom');
          },
        ),
        body: SingleChildScrollView(
          child: FutureBuilder(
              future: fetchJobById(this.jobId),
              builder: (BuildContext context, AsyncSnapshot<Job> snapshot) {
                if (snapshot.hasError) {
                  return Text('Deu ruim');
                }
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }
                return Container(
                  child: JobCard(
                    title: snapshot.data.title,
                    description: snapshot.data.description,
                  ),
                );
              }),
        ));
  }
}

_launchURL(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}
