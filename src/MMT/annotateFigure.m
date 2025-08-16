function [] = annotateFigure(fig, com, comtext)

%% PURPOSE: ANNOTATE THE EMG TIMESERIES WITH COMMENTS

% Put all of the comments in as vertical lines
figure(fig);
axHandles = findall(fig, 'Type', 'axes');
commentsIdx = com(:,3);
commentsNum = com(:,5); % The index of the comment value
comments = comtext;
for axNum = 1:length(axHandles)
    ax = axHandles(axNum);
    hold(ax, 'on');
    for commentCount = 1:length(commentsIdx)
        commentIdx = commentsIdx(commentCount);
        comment = comments(commentsNum(commentCount),:);
        xline(ax, commentIdx);
        ylims = ax.YLim;
        yVal = ylims(2) - diff(ylims)*0.1;
        xlims = ax.XLim;
        xVal = commentIdx - diff(xlims) * 0.02;
        text(ax, xVal, yVal, comment);
    end
end