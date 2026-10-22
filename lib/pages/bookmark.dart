// ignore_for_file: use_build_context_synchronously

import 'package:material_ui/material_ui.dart';
import 'package:iconsax/iconsax.dart';
import 'package:infinite_scroll/infinite_scroll.dart';
import 'package:kamus_investasi/databases/bookmarks/bookmark_repository.dart';
import 'package:kamus_investasi/models/dictionary_model.dart';
import 'package:kamus_investasi/pages/dictionary_detail.dart';

import '../shared/widgets/banner_ad_widget.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  final BookmarkRepository _bookmarkRepo = BookmarkRepository();

  int limit = 10;
  int pageList = 0;

  Future<List<DictionaryModel>> getNextPageData(int page) async {
    List<DictionaryModel>? data =
        await _bookmarkRepo.all(limit: limit, page: page);
    return data;
  }

  List<DictionaryModel> data = [];
  bool everyThingLoaded = false;
  bool isEmptyDictionary = false;
  bool isLastPage = false;

  void resetBool() {
    setState(() {
      pageList = 0;
      isEmptyDictionary = false;
      isLastPage = false;
      everyThingLoaded = false;
      data = [];
    });
  }

  Future<void> loadInitialData() async {
    data = await getNextPageData(pageList);
    if (data.isEmpty) {
      isEmptyDictionary = true;
    }

    if (data.isNotEmpty && data.length < limit) {
      isLastPage = true;
    }
    setState(() {});
  }

  Future deleteAllBookmark() async {
    await _bookmarkRepo.deleteAll();
    resetBool();
    loadInitialData();
  }

  Future<void> _refresh() async {
    resetBool();
    loadInitialData();
  }

  @override
  void initState() {
    loadInitialData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Scaffold(
            appBar: AppBar(
              title: const Text('Bookmark'),
              automaticallyImplyLeading: false,
              centerTitle: true,
              elevation: 0,
              backgroundColor: const Color.fromRGBO(65, 83, 181, 1),
              actions: [
                IconButton(
                    onPressed: () {
                      _deleteAllDialog();
                    },
                    icon: const Icon(Iconsax.star_15))
              ],
            ),
            backgroundColor: Colors.grey.shade100,
            body: RefreshIndicator(
              backgroundColor: Colors.white,
              color: const Color.fromRGBO(65, 83, 181, 1),
              displacement: 20,
              onRefresh: () => _refresh(),
              child: !isEmptyDictionary
                  ? InfiniteScrollList(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 15),
                      shrinkWrap: true,
                      loadingWidget: !isLastPage
                          ? const Center(
                              child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                      color: Color.fromRGBO(65, 83, 181, 1))),
                            )
                          : Container(),
                      onLoadingStart: (page) async {
                        pageList++;
                        List<DictionaryModel> newData =
                            await getNextPageData(pageList);
                        setState(() {
                          data += newData;
                          if (newData.isEmpty) {
                            everyThingLoaded = true;
                            isLastPage = true;
                          }
                        });
                      },
                      everythingLoaded: everyThingLoaded,
                      children: data
                          .map((item) => Container(
                                width: size.width,
                                margin: const EdgeInsets.only(
                                    left: 15, right: 15, bottom: 15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 10),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            onTap: () {
                                              Navigator.push(context,
                                                  MaterialPageRoute(
                                                      builder: (builder) {
                                                return DictionaryDetailScreen(
                                                  id: item.id,
                                                  isSetHistory: true,
                                                );
                                              }));
                                            },
                                            contentPadding: EdgeInsets.zero,
                                            leading: const Icon(Iconsax.star),
                                            title: Text(
                                              item.title ?? '',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Text(
                                                item.fullTitle != 'null'
                                                    ? item.fullTitle!
                                                    : item.description!,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    height: 1.5)),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ))
                          .toList())
                  : Center(
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: size.width * 0.5,
                            child: Image.asset('assets/images/bookmark.png')),
                        const SizedBox(
                          height: 15,
                        ),
                        const Text(
                          'Belum ada bookmark',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.grey),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text('Bookmark masih kosong.',
                            style: TextStyle(color: Colors.grey.shade400))
                      ],
                    )),
            )),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: BannerAdWidget(
              placement: BannerPlacement.bookmarkPage,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteAllDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Apakah kamu yakin ingin menghapus semua bookmark?',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Ya, Hapus',
                style: TextStyle(
                    color: Color.fromRGBO(65, 83, 181, 1),
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                await deleteAllBookmark();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
