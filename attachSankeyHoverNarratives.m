function attachSankeyHoverNarratives(axOrFig, SK, linksCell, narrativeMap, unitFormatStr)
% attachSankeyHoverNarratives Interactive Click + Arrow-Key Narrative Engine for SSankey
%   1. Exact True-Center Anchor Pin: Interpolates top and bottom rails at the
%      exact same X = xPin and places the anchor dot at the true geometric
%      vertical center of the ribbon: yMidAtPin = 0.5 * (yTopAtPin + yBotAtPin).
%   2. Canvas-Text Block Verification: Reads the actual text labels rendered
%      next to each block on the axes so the narrative box ALWAYS matches the
%      highlighted ribbon 100% of the time.
%   3. Full-Span Clearance & Arrow-Key Navigation (Up/Down/Left/Right/Esc).

if nargin < 4 || isempty(narrativeMap)
    narrativeMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
end

% 1. Resolve Figure and Axes handles
figHdl = ancestor(axOrFig, 'figure');
if isa(axOrFig, 'matlab.graphics.axis.Axes')
    axHdl = axOrFig;
else
    axHdl = findobj(figHdl, 'Type', 'axes', '-not', 'Tag', 'legend');
    if ~isempty(axHdl), axHdl = axHdl(1); end
end

if isempty(figHdl) || ~isgraphics(figHdl, 'figure')
    warning('attachSankeyHoverNarratives:NoFigure', 'Could not resolve figure handle.');
    return;
end

try set(figHdl, 'GraphicsSmoothing', 'on'); catch, end

if nargin < 5 || isempty(unitFormatStr)
    sampleLabel = '';
    if ~isempty(linksCell), sampleLabel = linksCell{1, 1}; end
    if ~contains(sampleLabel, '$') && contains(sampleLabel, '%')
        unitFormatStr = '%.1f%% of cohort';
    else
        unitFormatStr = 'NZD $%.2fk/yr per cohort birth';
    end
end

% 2. Clean up built-in MATLAB DataTips & any prior overlay objects
nukeAllDataTips(figHdl, axHdl);
delete(findall(axHdl, 'Tag', 'SSankeyLeaderLine'));
delete(findall(axHdl, 'Tag', 'SSankeyAnchorDot'));
delete(findall(axHdl, 'Tag', 'SSankeyThinSpine'));
delete(findall(axHdl, 'Tag', 'SSankeyHighlightRails'));
delete(findall(axHdl, 'Tag', 'SSankeyGradHighlight'));
delete(findall(axHdl, 'Tag', 'SSankeyRibbonOutline'));

allObjs = findall(axHdl);
for m = 1:numel(allObjs)
    if isprop(allObjs(m), 'ButtonDownFcn'), allObjs(m).ButtonDownFcn = ''; end
    if isprop(allObjs(m), 'PickableParts') && allObjs(m) ~= axHdl
        allObjs(m).PickableParts = 'none';
    end
    if isprop(allObjs(m), 'HitTest') && allObjs(m) ~= axHdl
        allObjs(m).HitTest = 'off';
    end
    try
        if isprop(allObjs(m), 'DataTipTemplate') && ~isempty(allObjs(m).DataTipTemplate)
            allObjs(m).DataTipTemplate.DataTipRows = [];
        end
    catch
    end
end

% 3. Match every BlockHdl(b) to its true Node Number by reading the actual
%    numbered text labels ('13. Core Skill...', '18. Age 30 PAYE...') on the axes!
nBlocks = numel(SK.BlockHdl);
blkBBox = nan(nBlocks, 4); % [xMin, xMax, yMin, yMax]
for b = 1:nBlocks
    if isgraphics(SK.BlockHdl(b))
        bx = double(SK.BlockHdl(b).XData(:));
        by = double(SK.BlockHdl(b).YData(:));
        blkBBox(b, :) = [min(bx), max(bx), min(by), max(by)];
    end
end

% Parse leading node numbers for every row of linksCell
nRowsCell  = size(linksCell, 1);
cellSrcNum = zeros(nRowsCell, 1);
cellTgtNum = zeros(nRowsCell, 1);
for r = 1:nRowsCell
    sTok = regexp(strtrim(linksCell{r, 1}), '^\d+', 'match', 'once');
    tTok = regexp(strtrim(linksCell{r, 2}), '^\d+', 'match', 'once');
    if ~isempty(sTok), cellSrcNum(r) = str2double(sTok); end
    if ~isempty(tTok), cellTgtNum(r) = str2double(tTok); end
end

% 4. Cache each ribbon's exact geometry, true Source/Target blocks, and color profile
nLinks     = numel(SK.LinkHdl);
origAlpha  = zeros(1, nLinks);
xGrid      = cell(1, nLinks); % Common monotonic X grid from xLeft to xRight
yTopGrid   = cell(1, nLinks); % Exact upper edge Y at xGrid
yBotGrid   = cell(1, nLinks); % Exact lower edge Y at xGrid
yMidGrid   = cell(1, nLinks); % True vertical center Y = 0.5*(yTopGrid + yBotGrid) at xGrid
polyX      = cell(1, nLinks);
polyY      = cell(1, nLinks);
ribThick   = zeros(nLinks, 1);
rgbStrip   = cell(1, nLinks);
bbox       = zeros(nLinks, 4);
linkSrcBlk = zeros(nLinks, 1);
linkTgtBlk = zeros(nLinks, 1);
yMidLeft   = zeros(nLinks, 1);
yMidRight  = zeros(nLinks, 1);
linkRow    = (1:nLinks)';

for k = 1:nLinks
    hP = SK.LinkHdl(k);
    if isgraphics(hP)
        origAlpha(k) = hP.FaceAlpha;
        hP.EdgeColor = 'none';

        [xg, yt, yb, ym, px, py, cProfile] = getTrueAlignedRibbonRails(hP);
        xGrid{k}    = xg;
        yTopGrid{k} = yt;
        yBotGrid{k} = yb;
        yMidGrid{k} = ym;
        polyX{k}    = px;
        polyY{k}    = py;
        ribThick(k) = median(yt - yb);
        rgbStrip{k} = cProfile;
        bbox(k, :)  = [min(px), max(px), min(py), max(py)];

        % Read exact un-interpolated left & right attachment edges directly from hP
        Xraw = double(hP.XData);
        Yraw = double(hP.YData);
        if size(Xraw, 1) == 2 && size(Xraw, 2) > 1
            xL    = mean(Xraw(:, 1));     xR    = mean(Xraw(:, end));
            yBotL = min(Yraw(:, 1));      yTopL = max(Yraw(:, 1));
            yBotR = min(Yraw(:, end));    yTopR = max(Yraw(:, end));
        else
            xL    = xg(1);                xR    = xg(end);
            yBotL = yb(1);                yTopL = yt(1);
            yBotR = yb(end);              yTopR = yt(end);
        end
        yMidLeft(k)  = 0.5 * (yBotL + yTopL);
        yMidRight(k) = 0.5 * (yBotR + yTopR);

        sBlk = matchRibbonEndToBlock(xL, yBotL, yTopL, blkBBox, 'right');
        tBlk = matchRibbonEndToBlock(xR, yBotR, yTopR, blkBBox, 'left');

        linkSrcBlk(k) = sBlk;
        linkTgtBlk(k) = tBlk;

        if sBlk > 0 && tBlk > 0 && isprop(SK, 'NodeList')
            sNum = str2double(regexp(strtrim(SK.NodeList{sBlk}), '^\d+', 'match', 'once'));
            tNum = str2double(regexp(strtrim(SK.NodeList{tBlk}), '^\d+', 'match', 'once'));
            mRow = find(cellSrcNum == sNum & cellTgtNum == tNum, 1);
            if ~isempty(mRow)
                linkRow(k) = mRow;
            end
        end
    end
end

% 5. Create Thin-Ribbon Visibility Spine + Leader Line + Center Anchor Dot
spineHdl = plot(axHdl, nan, nan, '-', ...
    'Tag',           'SSankeyThinSpine', ...
    'LineWidth',     2.6, ...
    'HitTest',       'off', ...
    'PickableParts', 'none', ...
    'Visible',       'off');
leaderHdl = plot(axHdl, nan, nan, '-', ...
    'Tag',           'SSankeyLeaderLine', ...
    'LineWidth',     1.8, ...
    'HitTest',       'off', ...
    'PickableParts', 'none', ...
    'Visible',       'off');
dotHdl = plot(axHdl, nan, nan, 'o', ...
    'Tag',           'SSankeyAnchorDot', ...
    'MarkerSize',    7.0, ...
    'LineWidth',     1.6, ...
    'HitTest',       'off', ...
    'PickableParts', 'none', ...
    'Visible',       'off');

% 6. Create the floating Narrative Box
delete(findall(figHdl, 'Tag', 'SSankeyHoverBox'));
hoverBox = annotation(figHdl, 'textbox', [0.20, 0.50, 0.42, 0.14], ...
    'Tag',               'SSankeyHoverBox', ...
    'String',            '', ...
    'BackgroundColor',   [1.00, 0.99, 0.95], ...
    'EdgeColor',         [0.25, 0.45, 0.55], ...
    'LineWidth',         2.2, ...
    'FontName',          'Helvetica', ...
    'FontSize',          9.5, ...
    'Interpreter',       'none', ...
    'FitBoxToText',      'on', ...
    'Margin',            8, ...
    'HitTest',           'off', ...
    'PickableParts',     'none', ...
    'Visible',           'off');

activeIdx  = 0;
anchorBlk  = 0;
anchorSide = 'src';

% 7. Bind Mouse Click & Keyboard Arrow Callbacks
set(figHdl, 'WindowButtonMotionFcn', '');
set(figHdl, 'WindowButtonDownFcn',   @onFigureClick);
set(figHdl, 'WindowKeyPressFcn',     @onKeyPress);

% =====================================================================
%  MOUSE CLICK CALLBACK
% =====================================================================
    function onFigureClick(~, ~)
        nukeAllDataTips(figHdl, axHdl);
        if ~isgraphics(axHdl), return; end

        cp = axHdl.CurrentPoint;
        mx = cp(1, 1);
        my = cp(1, 2);

        xl = axHdl.XLim;
        yl = axHdl.YLim;
        if mx < xl(1) || mx > xl(2) || my < yl(1) || my > yl(2)
            clearSelection();
            return;
        end

        % Check if user clicked directly on a Node Block
        clickedBlk = find(mx >= blkBBox(:,1) & mx <= blkBBox(:,2) & ...
            my >= blkBBox(:,3) & my <= blkBBox(:,4), 1);
        if ~isempty(clickedBlk)
            outLinks = find(linkSrcBlk == clickedBlk);
            inLinks  = find(linkTgtBlk == clickedBlk);
            if ~isempty(outLinks)
                anchorBlk  = clickedBlk;
                anchorSide = 'src';
                [~, topOrd]= max(yMidLeft(outLinks));
                xg         = xGrid{outLinks(topOrd)};
                selectRibbon(outLinks(topOrd), xg(round(0.28 * numel(xg))));
                return;
            elseif ~isempty(inLinks)
                anchorBlk  = clickedBlk;
                anchorSide = 'tgt';
                [~, topOrd]= max(yMidRight(inLinks));
                xg         = xGrid{inLinks(topOrd)};
                selectRibbon(inLinks(topOrd), xg(round(0.72 * numel(xg))));
                return;
            end
        end

        % Otherwise, find all ribbons whose polygon contains (mx, my)
        candidates = [];
        distToMid  = [];
        for idx = 1:nLinks
            if mx >= bbox(idx, 1) && mx <= bbox(idx, 2) && ...
                    my >= bbox(idx, 3) && my <= bbox(idx, 4)
                if inpolygon(mx, my, polyX{idx}, polyY{idx})
                    candidates(end+1) = idx; %#ok<AGROW>
                    xg = xGrid{idx};
                    ym = yMidGrid{idx};
                    [~, cNearest] = min(abs(xg - mx));
                    distToMid(end+1) = abs(my - ym(cNearest)); %#ok<AGROW>
                end
            end
        end

        if isempty(candidates)
            clearSelection();
            return;
        else
            [~, bestPos] = min(distToMid);
            hitIdx = candidates(bestPos);
        end

        if hitIdx == activeIdx
            clearSelection();
            return;
        end

        xg = xGrid{hitIdx};
        if abs(mx - xg(1)) <= abs(mx - xg(end))
            anchorBlk  = linkSrcBlk(hitIdx);
            anchorSide = 'src';
        else
            anchorBlk  = linkTgtBlk(hitIdx);
            anchorSide = 'tgt';
        end

        selectRibbon(hitIdx, mx);
    end

% =====================================================================
%  KEYBOARD ARROW NAVIGATION CALLBACK (UP / DOWN / LEFT / RIGHT / ESC)
% =====================================================================
    function onKeyPress(~, evt)
        if activeIdx == 0 || ~isgraphics(axHdl)
            return;
        end

        switch evt.Key
            case {'uparrow', 'downarrow'}
                if strcmp(anchorSide, 'src')
                    sibLinks = find(linkSrcBlk == anchorBlk);
                    [~, sortOrd] = sort(yMidLeft(sibLinks), 'ascend');
                else
                    sibLinks = find(linkTgtBlk == anchorBlk);
                    [~, sortOrd] = sort(yMidRight(sibLinks), 'ascend');
                end
                sibLinks = sibLinks(sortOrd);

                if numel(sibLinks) <= 1, return; end

                currPos = find(sibLinks == activeIdx, 1);
                if isempty(currPos), currPos = 1; end

                if strcmp(evt.Key, 'uparrow')
                    nextPos = currPos + 1;
                    if nextPos > numel(sibLinks), nextPos = 1; end
                else
                    nextPos = currPos - 1;
                    if nextPos < 1, nextPos = numel(sibLinks); end
                end

                nextIdx = sibLinks(nextPos);
                xg = xGrid{nextIdx};
                if strcmp(anchorSide, 'src')
                    refX = xg(min(numel(xg), max(1, round(0.28 * numel(xg)))));
                else
                    refX = xg(min(numel(xg), max(1, round(0.72 * numel(xg)))));
                end
                selectRibbon(nextIdx, refX);

            case 'rightarrow'
                if strcmp(anchorSide, 'src')
                    anchorBlk  = linkTgtBlk(activeIdx);
                    anchorSide = 'tgt';
                    xg   = xGrid{activeIdx};
                    refX = xg(min(numel(xg), max(1, round(0.72 * numel(xg)))));
                    selectRibbon(activeIdx, refX);
                else
                    outLinks = find(linkSrcBlk == anchorBlk);
                    if ~isempty(outLinks)
                        anchorSide = 'src';
                        [~, bestO] = min(abs(yMidLeft(outLinks) - yMidRight(activeIdx)));
                        nextIdx    = outLinks(bestO);
                        xg         = xGrid{nextIdx};
                        refX       = xg(min(numel(xg), max(1, round(0.28 * numel(xg)))));
                        selectRibbon(nextIdx, refX);
                    end
                end

            case 'leftarrow'
                if strcmp(anchorSide, 'tgt')
                    anchorBlk  = linkSrcBlk(activeIdx);
                    anchorSide = 'src';
                    xg   = xGrid{activeIdx};
                    refX = xg(min(numel(xg), max(1, round(0.28 * numel(xg)))));
                    selectRibbon(activeIdx, refX);
                else
                    inLinks = find(linkTgtBlk == anchorBlk);
                    if ~isempty(inLinks)
                        anchorSide = 'tgt';
                        [~, bestI] = min(abs(yMidRight(inLinks) - yMidLeft(activeIdx)));
                        nextIdx    = inLinks(bestI);
                        xg         = xGrid{nextIdx};
                        refX       = xg(min(numel(xg), max(1, round(0.72 * numel(xg)))));
                        selectRibbon(nextIdx, refX);
                    end
                end

            case {'escape', 'space'}
                clearSelection();
        end
    end

% =====================================================================
%  CORE RIBBON HIGHLIGHT & TRUE-CENTER PIN PLACEMENT
% =====================================================================
    function selectRibbon(hitIdx, refX)
        activeIdx = hitIdx;

        % 1. Spotlight active ribbon & dim background ribbons
        for idx = 1:nLinks
            if isgraphics(SK.LinkHdl(idx))
                if idx == hitIdx
                    SK.LinkHdl(idx).FaceAlpha = 0.90;
                else
                    SK.LinkHdl(idx).FaceAlpha = 0.12;
                end
            end
        end

        % 2. Find exact slice sIdx on the aligned X grid
        xg = xGrid{hitIdx};
        yt = yTopGrid{hitIdx};
        yb = yBotGrid{hitIdx};
        ym = yMidGrid{hitIdx};

        if nargin < 2 || isnan(refX)
            sIdx = round(0.5 * numel(xg));
        else
            [~, sIdx] = min(abs(xg - refX));
        end
        sIdx = min(max(sIdx, 5), max(5, numel(xg) - 4));

        % Exact coordinates at X = xPin:
        %   yCenterPin is the TRUE VERTICAL CENTER of the ribbon at xPin!
        xPin       = xg(sIdx);
        yTopLoc    = yt(sIdx);
        yBotLoc    = yb(sIdx);
        yCenterPin = ym(sIdx);

        % Sample exact RGB color of the ribbon at sIdx
        cProfile = rgbStrip{hitIdx};
        cLocal   = cProfile(min(sIdx, size(cProfile, 1)), :);
        cBorder  = max(0, min(1, 0.78 * cLocal));
        cTintBg  = 0.91 * [1, 1, 1] + 0.09 * cLocal;

        % Draw a glowing spine along the exact centerline if the ribbon is thin
        ySpanAx = diff(axHdl.YLim);
        if ribThick(hitIdx) < 0.025 * ySpanAx
            set(spineHdl, ...
                'XData',   xg, ...
                'YData',   ym, ...
                'Color',   cBorder, ...
                'Visible', 'on');
        else
            spineHdl.Visible = 'off';
        end

        % 3. Build Narrative + Anchor status text
        rIdx    = linkRow(hitIdx);
        rawSrc  = linksCell{rIdx, 1};
        rawTgt  = linksCell{rIdx, 2};
        flowVal = linksCell{rIdx, 3};

        srcClean = regexprep(rawSrc, '\s*\n\s*', ' ');
        tgtClean = regexprep(rawTgt, '\s*\n\s*', ' ');

        srcNum = regexp(strtrim(rawSrc), '^\d+', 'match', 'once');
        tgtNum = regexp(strtrim(rawTgt), '^\d+', 'match', 'once');
        key    = sprintf('%s->%s', srcNum, tgtNum);

        unitStr = sprintf(unitFormatStr, flowVal);

        if strcmp(anchorSide, 'src')
            anchorTag = sprintf('Node %s (Left/Source)', srcNum);
        else
            anchorTag = sprintf('Node %s (Right/Target)', tgtNum);
        end

        if isKey(narrativeMap, key)
            info = narrativeMap(key);
            txt = sprintf(['[%s]  -->  [%s]\n', ...
                '• Ribbon Flow: %s   |   %s\n', ...
                '• Mechanism: %s\n', ...
                '• Citation: %s\n', ...
                '[Anchor: %s | Up/Down: cycle ribbons | Left/Right: switch block | Click/Esc: close]'], ...
                srcClean, tgtClean, unitStr, ...
                info.direction, info.mechanism, info.citation, anchorTag);
        else
            txt = sprintf(['[%s]  -->  [%s]\n', ...
                '• Ribbon Flow: %s   |   Transition: Node %s -> Node %s\n', ...
                '[Anchor: %s | Up/Down: cycle ribbons | Left/Right: switch block | Click/Esc: close]'], ...
                srcClean, tgtClean, unitStr, srcNum, tgtNum, anchorTag);
        end

        hoverBox.EdgeColor       = cBorder;
        hoverBox.BackgroundColor = cTintBg;
        hoverBox.String          = txt;
        drawnow limitrate;

        posNow = hoverBox.Position;
        boxW   = min(max(posNow(3), 0.36), 0.46);
        boxH   = min(max(posNow(4), 0.12), 0.19);

        % 4. Place box above or below the active ribbon span, and connect the
        %    leader line & anchor dot directly to the ribbon's TRUE CENTER (xPin, yCenterPin)!
        [boxX, boxY, boxAnchorAxesX, boxAnchorAxesY] = ...
            computeFullSpanBoxAndCenterPin(axHdl, xPin, yBotLoc, yTopLoc, xg, yb, yt, boxW, boxH);

        hoverBox.Position = [boxX, boxY, boxW, boxH];
        hoverBox.Visible  = 'on';

        % 5. Draw color-matched Leader Line + Anchor Dot dead-center in the ribbon!
        set(leaderHdl, ...
            'XData',   [xPin,       boxAnchorAxesX], ...
            'YData',   [yCenterPin, boxAnchorAxesY], ...
            'Color',   cBorder, ...
            'Visible', 'on');
        set(dotHdl, ...
            'XData',           xPin, ...
            'YData',           yCenterPin, ...
            'MarkerEdgeColor', [1, 1, 1], ...
            'MarkerFaceColor', cBorder, ...
            'Visible',         'on');
    end

    function clearSelection()
        if activeIdx > 0
            for idx = 1:nLinks
                if isgraphics(SK.LinkHdl(idx))
                    SK.LinkHdl(idx).FaceAlpha = origAlpha(idx);
                end
            end
        end
        activeIdx         = 0;
        hoverBox.Visible  = 'off';
        leaderHdl.Visible = 'off';
        dotHdl.Visible    = 'off';
        spineHdl.Visible  = 'off';
    end
end

%% ========================================================================
%  FULL-SPAN RIBBON CLEARANCE + TRUE RIBBON-CENTER PIN
%  ========================================================================
function [boxX, boxY, boxAnchorAxesX, boxAnchorAxesY] = ...
    computeFullSpanBoxAndCenterPin(axHdl, xPin, yBotLoc, yTopLoc, xg, yBotVec, yTopVec, boxW, boxH)

oldUnits = axHdl.Units;
axHdl.Units = 'normalized';
axPos = axHdl.Position; % [axL, axB, axW, axH]
axHdl.Units = oldUnits;

xl = axHdl.XLim;
yl = axHdl.YLim;

figX    = axPos(1) + ((xPin    - xl(1)) / diff(xl)) * axPos(3);
figXRibR= axPos(1) + ((xg(end) - xl(1)) / diff(xl)) * axPos(3);

minX = 0.02;  maxX = 0.98;
minY = 0.13;  maxY = 0.90;
gapY = 0.024; % breathing room between ribbon edge and narrative box

% Shift box horizontally to the LEFT of the destination block (figXRibR)
% so it NEVER covers the destination block's right-hand statistics label,
% AND so on upward-sloping ribbons (like 13->18) it sits over the lower
% left-hand valley of the ribbon rather than the high right-hand end!
maxRightEdge = max(minX + boxW, min(maxX, figXRibR - 0.015));
idealBoxX    = figX - 0.72 * boxW; % bias left of the pin point
boxX         = min(max(idealBoxX, minX), maxRightEdge - boxW);

% Check the highest and lowest Y of the ribbon ONLY where the box & ribbon
% could actually intersect near the pin (left-biased window), so a steep rise
% to the right of the box doesn't push the box into the ceiling!
xBoxLeftAx  = xl(1) + ((boxX        - axPos(1)) / axPos(3)) * diff(xl);
xBoxRightAx = xl(1) + ((boxX + boxW - axPos(1)) / axPos(3)) * diff(xl);

inSpan = (xg >= xBoxLeftAx) & (xg <= xBoxRightAx);
if any(inSpan)
    yHighSpan = max(yTopVec(inSpan));
    yLowSpan  = min(yBotVec(inSpan));
else
    yHighSpan = yTopLoc;
    yLowSpan  = yBotLoc;
end

figYHigh = axPos(2) + ((yHighSpan - yl(1)) / diff(yl)) * axPos(4);
figYLow  = axPos(2) + ((yLowSpan  - yl(1)) / diff(yl)) * axPos(4);

% Check if ribbon is rising (ym(end) > ym(1)) vs falling
isRising = (yTopVec(end) + yBotVec(end)) > (yTopVec(1) + yBotVec(1));

spaceAbove = maxY - (figYHigh + gapY);
spaceBelow = (figYLow  - gapY) - minY;

if isRising && spaceAbove >= boxH
    % Rising ribbon (e.g. 13->18): open valley is ABOVE-LEFT of the ribbon!
    boxY        = figYHigh + gapY;
    figBoxEdgeY = boxY;        % attach leader to bottom edge of box
elseif ~isRising && spaceBelow >= boxH
    % Falling ribbon: open valley is BELOW-LEFT of the ribbon!
    boxY        = figYLow - gapY - boxH;
    figBoxEdgeY = boxY + boxH; % attach leader to top edge of box
elseif spaceBelow >= boxH && spaceBelow >= spaceAbove
    boxY        = figYLow - gapY - boxH;
    figBoxEdgeY = boxY + boxH;
elseif spaceAbove >= boxH
    boxY        = figYHigh + gapY;
    figBoxEdgeY = boxY;
else
    % Tight vertical span: place directly above or below the local slice at xPin
    figYLocTop = axPos(2) + ((yTopLoc - yl(1)) / diff(yl)) * axPos(4);
    figYLocBot = axPos(2) + ((yBotLoc - yl(1)) / diff(yl)) * axPos(4);
    if spaceAbove >= spaceBelow
        boxY        = min(maxY - boxH, figYLocTop + gapY);
        figBoxEdgeY = boxY;
    else
        boxY        = max(minY, figYLocBot - gapY - boxH);
        figBoxEdgeY = boxY + boxH;
    end
end

figBoxAttachX  = min(max(figX, boxX + 0.025), boxX + boxW - 0.025);
boxAnchorAxesX = xl(1) + ((figBoxAttachX - axPos(1)) / axPos(3)) * diff(xl);
boxAnchorAxesY = yl(1) + ((figBoxEdgeY   - axPos(2)) / axPos(4)) * diff(yl);
end

%% ========================================================================
%  ALIGN TOP & BOTTOM SURFACE RAILS TO IDENTICAL X GRID FOR TRUE CENTERLINE
%  ========================================================================
function [xg, yt, yb, ym, px, py, cProfile] = getTrueAlignedRibbonRails(hP)
% Because SSankey rotates the ribbon normal along steep curves, XData(1,c)
% and XData(2,c) have different X coordinates at column index c!
% Resampling both rails onto a shared monotonic X grid [xLeft .. xRight]
% ensures yt(c) and yb(c) are evaluated at the EXACT same X coordinate xg(c),
% so ym(c) = 0.5*(yt(c) + yb(c)) is the true vertical center of the ribbon!

X  = double(hP.XData);
Y  = double(hP.YData);
CD = double(hP.CData);

if size(X, 1) == 2 && size(X, 2) > 1
    x1 = X(1, :);  y1 = Y(1, :);
    x2 = X(2, :);  y2 = Y(2, :);
    nPts = size(X, 2);
    cProfile = repmat([0.25, 0.50, 0.65], nPts, 1);
    if ndims(CD) == 3 && size(CD, 2) == nPts && size(CD, 3) == 3
        cProfile = squeeze(mean(CD, 1, 'omitnan'));
    end
elseif size(X, 2) == 2 && size(X, 1) > 1
    x1 = X(:, 1)'; y1 = Y(:, 1)';
    x2 = X(:, 2)'; y2 = Y(:, 2)';
    nPts = size(X, 1);
    cProfile = repmat([0.25, 0.50, 0.65], nPts, 1);
    if ndims(CD) == 3 && size(CD, 1) == nPts && size(CD, 3) == 3
        cProfile = squeeze(mean(CD, 2, 'omitnan'));
    end
else
    xv = X(:)';    yv = Y(:)';
    nHalf = floor(numel(xv) / 2);
    x1 = xv(1:nHalf);             y1 = yv(1:nHalf);
    x2 = fliplr(xv(nHalf+1:end)); y2 = fliplr(yv(nHalf+1:end));
    nPts = nHalf;
    cProfile = repmat([0.25, 0.50, 0.65], nPts, 1);
end

% Keep exact closed polygon for inpolygon hit-testing
px = [x1, fliplr(x2), x1(1)]';
py = [y1, fliplr(y2), y1(1)]';

% Resample both rails onto a shared X grid xg WITHOUT extrapolation overshoot
xL = min(mean(x1(1), x2(1)), min([x1, x2]));
xR = max(mean(x1(end), x2(end)), max([x1, x2]));
xg = linspace(xL, xR, nPts);

[u1, ia1] = unique(x1, 'stable');
[u2, ia2] = unique(x2, 'stable');
if numel(u1) >= 2 && numel(u2) >= 2
    % Clamp query points to [min(u), max(u)] so interp1 NEVER extrapolates!
    q1 = min(max(xg, min(u1)), max(u1));
    q2 = min(max(xg, min(u2)), max(u2));
    y1_interp = interp1(u1, y1(ia1), q1, 'linear');
    y2_interp = interp1(u2, y2(ia2), q2, 'linear');
else
    y1_interp = y1;
    y2_interp = y2;
end

yt = max(y1_interp, y2_interp);
yb = min(y1_interp, y2_interp);
ym = 0.5 * (yt + yb);
end

function blkIdx = matchRibbonEndToBlock(xEnd, yBotEnd, yTopEnd, blkBBox, side)
% Matches a ribbon's vertical end-segment [yBotEnd, yTopEnd] at xEnd to the
% BlockHdl in that Gate column with the maximum vertical overlap.
if strcmp(side, 'right')
    dx = abs(blkBBox(:, 2) - xEnd);
else
    dx = abs(blkBBox(:, 1) - xEnd);
end
colBlks = find(dx < min(dx) + 0.15);

% Compute vertical overlap between [yBotEnd, yTopEnd] and each block's [yMin, yMax]
ov = min(yTopEnd, blkBBox(colBlks, 4)) - max(yBotEnd, blkBBox(colBlks, 3));
[maxOv, best] = max(ov);
if maxOv > -1e-3
    blkIdx = colBlks(best);
else
    yMidEnd = 0.5 * (yBotEnd + yTopEnd);
    yMids   = 0.5 * (blkBBox(colBlks, 3) + blkBBox(colBlks, 4));
    [~, b2] = min(abs(yMids - yMidEnd));
    blkIdx  = colBlks(b2);
end
end

function nukeAllDataTips(figHdl, axHdl)
try disableDefaultInteractivity(axHdl); catch, end
try if isprop(axHdl, 'Interactions'), axHdl.Interactions = []; end; catch, end
try
    dcm = datacursormode(figHdl);
    dcm.removeAllDataCursors();
    dcm.Enable = 'off';
catch
end
try
    dt1 = findall(figHdl, '-isa', 'matlab.graphics.shape.internal.PointDataTip');
    if ~isempty(dt1), delete(dt1); end
    dt2 = findall(figHdl, 'Type', 'datatip');
    if ~isempty(dt2), delete(dt2); end
    dt3 = findall(figHdl, 'Tag', 'DataTipMarker');
    if ~isempty(dt3), delete(dt3); end
catch
end
end
