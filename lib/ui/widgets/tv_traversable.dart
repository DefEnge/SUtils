import 'package:flutter/material.dart';

class TvTraversable extends StatelessWidget {

    final ScrollController? scrollController;
    final Widget child;

    const TvTraversable({
        super.key,
        required this.child,
        this.scrollController
    });

    @override
    Widget build(BuildContext context) {
        return FocusTraversalGroup(
            policy: _RowListTraversalPolicy(this.scrollController),
            child: this.child
        );
    }
}

class _RowListTraversalPolicy extends ReadingOrderTraversalPolicy {

    final ScrollController? scrollController;
    _RowListTraversalPolicy(this.scrollController);

    List<FocusNode> _sortedChildrenByX(FocusNode node) {
        List<FocusNode> siblings = node.children.toList();
        siblings.sort((a, b) {
            RenderBox aBox = a.context!.findRenderObject() as RenderBox;
            RenderBox bBox = b.context!.findRenderObject() as RenderBox;
            return aBox.localToGlobal(Offset.zero).dx.compareTo(bBox.localToGlobal(Offset.zero).dx);
        });
        return siblings;
    }

    List<FocusNode> _sortedChildrenByY(FocusNode node) {
        List<FocusNode> siblings = node.children.toList();
        siblings.sort((a, b) {
            RenderBox aBox = a.context!.findRenderObject() as RenderBox;
            RenderBox bBox = b.context!.findRenderObject() as RenderBox;
            return aBox.localToGlobal(Offset.zero).dy.compareTo(bBox.localToGlobal(Offset.zero).dy);
        });
        return siblings;
    }

    @override
    bool inDirection(FocusNode currentNode, TraversalDirection direction) {
        FocusNode row = currentNode.parent!;
        FocusNode list = row.parent!;
        List<FocusNode> siblings = this._sortedChildrenByX(row);

        if (direction == TraversalDirection.down || direction == TraversalDirection.up) {
            List<FocusNode> rows = this._sortedChildrenByY(list);
            rows.removeWhere((row) => row.children.isEmpty);
            int index = rows.indexOf(row);

            FocusNode? nextRow;
            if (direction == TraversalDirection.down && index + 1 < rows.length)
                nextRow = rows[index + 1];
            else if (direction == TraversalDirection.up && index > 0)
                nextRow = rows[index - 1];

            FocusNode? target = nextRow == null ? null : this._sortedChildrenByX(nextRow).firstOrNull;
            if(target != null) {
                target.requestFocus();
                Scrollable.ensureVisible(
                    target.parent?.context! ?? target.context!,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignmentPolicy: direction == TraversalDirection.down
                        ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
                        : ScrollPositionAlignmentPolicy.keepVisibleAtStart
                ).then((_) => scrollController?.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut
                ));
                return true;
            }
        }

        if(direction == TraversalDirection.right) {
            int index = siblings.indexOf(currentNode);

            if(index != -1) {
                if(index == siblings.length - 1)
                    return false;
            }
        }

        if(direction == TraversalDirection.left) {
            int index = siblings.indexOf(currentNode);

            if(index == 0) {
                if(this.scrollController == null || this.scrollController?.offset == 0)
                    return false;

                this.scrollController?.animateTo(
                    this.scrollController!.offset - MediaQuery.of(row.context!).size.width / 5.5 * 2,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut
                );
            }
        }

        return super.inDirection(currentNode, direction);
    }
}