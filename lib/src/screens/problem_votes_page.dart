import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../api/vote.dart';
import '../models/problem_vote.dart';
import '../utils/color_schemes.dart';
import '../widgets/problem_vote_compose.dart';
import '../widgets/problem_vote_list_item.dart';

class ProblemVotesPage extends HookWidget {
  final String problemId;

  const ProblemVotesPage({super.key, required this.problemId});

  @override
  Widget build(BuildContext context) {
    const pageSize = 20;
    
    final pagingController = useMemoized(
      () => PagingController<int, ProblemVote>(firstPageKey: 0),
    );

    useEffect(() {
      void fetchPage(int pageKey) async {
        try {
          final votes = await ProblemVoteApi.getVotes(
            problemId: problemId, 
            page: pageKey, 
            size: pageSize,
          );
          
          final isLastPage = votes.length < pageSize;
          if (isLastPage) {
            pagingController.appendLastPage(votes);
          } else {
            final nextPageKey = pageKey + 1;
            pagingController.appendPage(votes, nextPageKey);
          }
        } catch (error) {
          pagingController.error = error;
        }
      }

      pagingController.addPageRequestListener(fetchPage);
      return () => pagingController.dispose();
    }, []);

    void refreshAfterSubmit() {
      pagingController.refresh();
    }

    return Scaffold(
      backgroundColor: AppColorSchemes.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColorSchemes.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColorSchemes.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '난이도 기여',
          style: TextStyle(color: AppColorSchemes.textPrimary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProblemVoteCompose(problemId: problemId, onSubmitted: refreshAfterSubmit),
            const SizedBox(height: 16),
            Expanded(
              child: PagedListView<int, ProblemVote>(
                pagingController: pagingController,
                builderDelegate: PagedChildBuilderDelegate<ProblemVote>(
                  itemBuilder: (context, item, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ProblemVoteListItem(vote: item),
                  ),
                  firstPageErrorIndicatorBuilder: (context) => _buildError(
                    context, 
                    pagingController.error.toString(),
                  ),
                  noItemsFoundIndicatorBuilder: (context) => _buildEmpty(),
                  newPageProgressIndicatorBuilder: (context) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColorSchemes.accentRed, size: 48),
          const SizedBox(height: 12),
          Text('불러오기 실패: $message', style: const TextStyle(color: AppColorSchemes.textSecondary)),
        ],
      ),
    );
  }


  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColorSchemes.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColorSchemes.borderPrimary),
      ),
      child: const Text(
        '아직 등록된 의견이 없어요. 첫 의견을 남겨보세요!',
        style: TextStyle(color: AppColorSchemes.textSecondary),
      ),
    );
  }
}


