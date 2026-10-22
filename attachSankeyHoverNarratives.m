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

% 3. Cache BlockHdl bounding boxes, exact Gate Column (1..6), and Block Y-midpoints
nBlocks = numel(SK.BlockHdl);
blkBBox = nan(nBlocks, 4); % [xMin, xMax, yMin, yMax] in axes units
for b = 1:nBlocks
    if isgraphics(SK.BlockHdl(b))
        bx = double(SK.BlockHdl(b).XData(:));
        by = double(SK.BlockHdl(b).YData(:));
        blkBBox(b, :) = [min(bx), max(bx), min(by), max(by)];
    end
end
blkXMid = 0.5 * (blkBBox(:, 1) + blkBBox(:, 2));
blkYMid = 0.5 * (blkBBox(:, 3) + blkBBox(:, 4));
[~, ~, blkGateCol] = uniquetol(blkXMid, 0.25, 'DataScale', 1); % Exact Gate column 1..6!

% Build 1-to-1 right-hand label avoidance zones (nBlocks x 4) indexed by block b
% so computeFullSpanBoxAndCenterPin can look up lblBBox(sBlk,:) and lblBBox(tBlk,:) directly
ySpanAx = diff(axHdl.YLim);
lblBBox = nan(nBlocks, 4);
for b = 1:nBlocks
    if ~isnan(blkBBox(b, 1))
        ymB = blkYMid(b);
        lblBBox(b, :) = [blkBBox(b, 2), blkBBox(b, 2) + 0.48, ...
            ymB - 0.045 * ySpanAx, ymB + 0.045 * ySpanAx];
    end
end

% Build 1-to-1 right-hand label avoidance zones (nBlocks x 4) indexed by block b
% so computeFullSpanBoxAndCenterPin can look up lblBBox(sBlk,:) and lblBBox(tBlk,:) directly
ySpanAx = diff(axHdl.YLim);
lblBBox = nan(nBlocks, 4);
for b = 1:nBlocks
    if ~isnan(blkBBox(b, 1))
        ymB = blkYMid(b);
        lblBBox(b, :) = [blkBBox(b, 2), blkBBox(b, 2) + 0.48, ...
            ymB - 0.045 * ySpanAx, ymB + 0.045 * ySpanAx];
    end
end

% Cache each block's text handle (SK.LabelHdl) & original font styling for bold highlighting
blkLblHdl      = gobjects(nBlocks, 1);
origLblWeight  = cell(nBlocks, 1);
origLblSize    = zeros(nBlocks, 1);
origLblColor   = cell(nBlocks, 1);
if isprop(SK, 'LabelHdl') && numel(SK.LabelHdl) == nBlocks
    blkLblHdl = SK.LabelHdl(:);
else
    allAxTxts = findall(axHdl, 'Type', 'text');
    for b = 1:nBlocks
        if isprop(SK, 'NodeList') && b <= numel(SK.NodeList)
            mTxt = findobj(allAxTxts, 'String', SK.NodeList{b});
            if ~isempty(mTxt), blkLblHdl(b) = mTxt(1); end
        end
    end
end
for b = 1:nBlocks
    if isgraphics(blkLblHdl(b))
        origLblWeight{b} = blkLblHdl(b).FontWeight;
        origLblSize(b)   = blkLblHdl(b).FontSize;
        origLblColor{b}  = blkLblHdl(b).Color;
    end
end

% 4. Map SK.LinkHdl(k) using SSankey's EXACT internal drawLink(k) indexing:
%    Inside SSankey.drawLink(n): [sInd, tInd] = find(obj.BoolMat);
nLinks     = numel(SK.LinkHdl);
origAlpha  = zeros(1, nLinks);
xGrid      = cell(1, nLinks);
yTopGrid   = cell(1, nLinks);
yBotGrid   = cell(1, nLinks);
yMidGrid   = cell(1, nLinks);
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

% Replicate SSankey.drawLink's exact column-major find() on BoolMat / AdjMat
if isprop(SK, 'BoolMat') && ~isempty(SK.BoolMat)
    [sIndVec, tIndVec] = find(SK.BoolMat);
elseif isprop(SK, 'AdjMat') && ~isempty(SK.AdjMat)
    [sIndVec, tIndVec] = find(SK.AdjMat ~= 0);
else
    sIndVec = zeros(nLinks, 1);
    tIndVec = zeros(nLinks, 1);
end

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
        yMidLeft(k) = ym(1);
        yMidRight(k)= ym(end);

        if k <= numel(sIndVec) && sIndVec(k) > 0 && tIndVec(k) > 0
            sBlk = sIndVec(k);
            tBlk = tIndVec(k);
            linkSrcBlk(k) = sBlk;
            linkTgtBlk(k) = tBlk;

            % Interpolate exact RGB profile from Source Block color to Target Block color!
            cS = getBlockRGB(SK, sBlk);
            cT = getBlockRGB(SK, tBlk);
            wVec = linspace(0, 1, numel(xg))';
            rgbStrip{k} = (1 - wVec) * cS + wVec * cT;

            sName = SK.NodeList{sBlk};
            tName = SK.NodeList{tBlk};
            mRow  = find(strcmp(linksCell(:, 1), sName) & strcmp(linksCell(:, 2), tName), 1);
            if ~isempty(mRow)
                linkRow(k) = mRow;
            end
        end
    end
end

% 5. Create Thin-Ribbon Visibility Spine + Leader Line + Center Anchor Dot
leaderHdl = plot(axHdl, nan, nan, ':', ...
    'Tag',           'SSankeyLeaderLine', ...
    'LineWidth',     1.5, ...
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
                % 1. Outer Hierarchy: All blocks in the current Gate column, sorted bottom-to-top
                currGate = blkGateCol(anchorBlk);
                gateBlks = find(blkGateCol == currGate);
                [~, blkOrd] = sort(blkYMid(gateBlks), 'ascend'); % bottom block -> top block
                gateBlks = gateBlks(blkOrd);

                % 2. Inner Hierarchy: Within each block b in this Gate, sort its ribbons
                %    by the vertical height (blkYMid) of the partner block at the other end!
                hierLinks = [];
                minVisThick = 0.0015 * diff(axHdl.YLim);
                for bIdx = 1:numel(gateBlks)
                    b = gateBlks(bIdx);
                    if strcmp(anchorSide, 'src')
                        bLinks = find(linkSrcBlk == b);
                        % Skip invisible phantom ($0.00k / $0.01k) ribbons!
                        bFlows = cell2mat(linksCell(linkRow(bLinks), 3));
                        bLinks = bLinks(bFlows >= 0.05 & ribThick(bLinks) >= minVisThick);
                        [~, partnerOrd] = sort(blkYMid(linkTgtBlk(bLinks)), 'ascend');
                    else
                        bLinks = find(linkTgtBlk == b);
                        bFlows = cell2mat(linksCell(linkRow(bLinks), 3));
                        bLinks = bLinks(bFlows >= 0.05 & ribThick(bLinks) >= minVisThick);
                        [~, partnerOrd] = sort(blkYMid(linkSrcBlk(bLinks)), 'ascend');
                    end
                    hierLinks = [hierLinks; bLinks(partnerOrd(:))]; %#ok<AGROW>
                end

                if numel(hierLinks) <= 1, return; end

                currPos = find(hierLinks == activeIdx, 1);
                if isempty(currPos), currPos = 1; end

                % UpArrow moves UP the hierarchy (increasing Y); DownArrow moves DOWN (decreasing Y)
                if strcmp(evt.Key, 'uparrow')
                    nextPos = currPos + 1;
                    if nextPos > numel(hierLinks), nextPos = 1; end
                else
                    nextPos = currPos - 1;
                    if nextPos < 1, nextPos = numel(hierLinks); end
                end

                nextIdx = hierLinks(nextPos);
                if strcmp(anchorSide, 'src')
                    anchorBlk = linkSrcBlk(nextIdx);
                else
                    anchorBlk = linkTgtBlk(nextIdx);
                end

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

        % Bold the active Source & Target block labels so they stand out clearly!
        sBlkAct = linkSrcBlk(hitIdx);
        tBlkAct = linkTgtBlk(hitIdx);
        for b = 1:nBlocks
            if isgraphics(blkLblHdl(b))
                if b == sBlkAct || b == tBlkAct
                    blkLblHdl(b).FontWeight = 'bold';
                    blkLblHdl(b).FontSize   = origLblSize(b) + 0.5;
                    blkLblHdl(b).Color      = [0.05, 0.05, 0.05];
                else
                    blkLblHdl(b).FontWeight = origLblWeight{b};
                    blkLblHdl(b).FontSize   = origLblSize(b);
                    blkLblHdl(b).Color      = 0.85 * origLblColor{b} + 0.15 * [1, 1, 1];
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
        % If ribbon is visible but thin, boost its alpha to 1.0 (no separate spine line!)
        if ribThick(hitIdx) < 0.025 * diff(axHdl.YLim)
            SK.LinkHdl(hitIdx).FaceAlpha = 1.0;
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
            computeFullSpanBoxAndCenterPin(axHdl, xPin, yBotLoc, yTopLoc, xg, yb, yt, ...
            boxW, boxH, lblBBox, linkSrcBlk(hitIdx), linkTgtBlk(hitIdx));

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
            for b = 1:nBlocks
                if isgraphics(blkLblHdl(b))
                    blkLblHdl(b).FontWeight = origLblWeight{b};
                    blkLblHdl(b).FontSize   = origLblSize(b);
                    blkLblHdl(b).Color      = origLblColor{b};
                end
            end
        end
        activeIdx         = 0;
        hoverBox.Visible  = 'off';
        leaderHdl.Visible = 'off';
        dotHdl.Visible    = 'off';
    end
end

%% ========================================================================
%  FULL-SPAN RIBBON CLEARANCE + TRUE RIBBON-CENTER PIN
%  ========================================================================
function [boxX, boxY, boxAnchorAxesX, boxAnchorAxesY] = ...
    computeFullSpanBoxAndCenterPin(axHdl, xPin, yBotLoc, yTopLoc, xg, yBotVec, yTopVec, ...
    boxW, boxH, lblBBox, sBlk, tBlk)

oldUnits = axHdl.Units;
axHdl.Units = 'normalized';
axPos = axHdl.Position; % [axL, axB, axW, axH]
axHdl.Units = oldUnits;

xl = axHdl.XLim;
yl = axHdl.YLim;

toFigX = @(axX) axPos(1) + ((axX - xl(1)) ./ diff(xl)) .* axPos(3);
toFigY = @(axY) axPos(2) + ((axY - yl(1)) ./ diff(yl)) .* axPos(4);
toAxX  = @(fgX) xl(1) + ((fgX - axPos(1)) ./ axPos(3)) .* diff(xl);
toAxY  = @(fgY) yl(1) + ((fgY - axPos(2)) ./ axPos(4)) .* diff(yl);

figX     = toFigX(xPin);
figXRibL = toFigX(xg(1));
figXRibR = toFigX(xg(end));
figYPin  = toFigY(0.5 * (yBotLoc + yTopLoc));
figYTop  = toFigY(yTopLoc);
figYBot  = toFigY(yBotLoc);

minX = 0.02;  maxX = 0.96;
minY = 0.125; maxY = 0.935;
gapY = 0.020;

% Convert ALL block right-hand label zones into normalized figure rectangles [x1, x2, y1, y2]
nB      = size(lblBBox, 1);
figLbls = nan(nB, 4);
for b = 1:nB
    if ~isnan(lblBBox(b, 1))
        figLbls(b, :) = [toFigX(lblBBox(b,1)), toFigX(lblBBox(b,2)), ...
            toFigY(lblBBox(b,3)), toFigY(lblBBox(b,4))];
    end
end

% Candidate X positions:
%   - Centered on xPin, biased left/right
%   - Strictly to the LEFT of Source bar (figXRibL - boxW - 0.018): zero overlap with
%     either the active ribbon OR the Source block's right-hand label!
%   - Strictly to the LEFT of Target bar (figXRibR - boxW - 0.015): protects Target label!
%   - Strictly to the RIGHT of Target bar (for Gate 1 ribbons)
candX = unique(min(max([ ...
    figX - 0.50 * boxW, ...
    figX - 0.75 * boxW, ...
    figX - 0.25 * boxW, ...
    figXRibL - boxW - 0.018, ...
    figXRibR - boxW - 0.015, ...
    figXRibR + 0.018 ...
    ], minX), maxX - boxW));

bestScore = inf;
boxX      = candX(1);
boxY      = minY;

for c = 1:numel(candX)
    cx   = candX(c);
    xAx1 = toAxX(cx);
    xAx2 = toAxX(cx + boxW);

    % Active ribbon's vertical span inside this candidate box's horizontal footprint [cx, cx+boxW]
    fullSpan = (xg >= xAx1) & (xg <= xAx2);
    if any(fullSpan)
        rHigh = toFigY(max(yTopVec(fullSpan)));
        rLow  = toFigY(min(yBotVec(fullSpan)));
    else
        rHigh = figYTop;
        rLow  = figYBot;
    end

    % Candidate Y positions:
    %   - Above/below the ribbon's span in [cx, cx+boxW]
    %   - Above/below/centered on the local pin (figYPin), which works cleanly
    %     when the box is shifted to the left of a steep rising ribbon like 13->20!
    candY = unique([ ...
        rHigh + gapY, ...
        rLow  - gapY - boxH, ...
        figYTop + gapY, ...
        figYBot - gapY - boxH, ...
        figYPin - 0.50 * boxH, ...
        figYPin + 0.015, ...
        figYPin - boxH - 0.015 ...
        ]);

    for s = 1:numel(candY)
        cy = candY(s);

        oobPen = 0;
        if cy < minY
            oobPen = 8000 * (minY - cy);
            cy = minY;
        elseif cy + boxH > maxY
            oobPen = 8000 * ((cy + boxH) - maxY);
            cy = maxY - boxH;
        end

        % 1. Strictly penalize overlapping any slice of the active ribbon inside [cx, cx+boxW]
        ribPen = 0;
        if any(fullSpan)
            idxSpan = find(fullSpan);
            for ii = idxSpan(:)'
                sTop = toFigY(yTopVec(ii)) + 0.005;
                sBot = toFigY(yBotVec(ii)) - 0.005;
                ovSlice = max(0, min(cy + boxH, sTop) - max(cy, sBot));
                if ovSlice > 0
                    ribPen = ribPen + 500 + 80000 * ovSlice;
                end
            end
        end

        % 2. Penalize overlapping ANY block's right-hand label (extra weight on sBlk & tBlk)
        lblPen = 0;
        for b = 1:nB
            if ~isnan(figLbls(b, 1))
                ox = max(0, min(cx + boxW, figLbls(b, 2)) - max(cx, figLbls(b, 1)));
                oy = max(0, min(cy + boxH, figLbls(b, 4)) - max(cy, figLbls(b, 3)));
                if ox > 0 && oy > 0
                    if b == sBlk || b == tBlk
                        lblPen = lblPen + 200 + 80000 * (ox * oy);
                    else
                        lblPen = lblPen + 80 + 35000 * (ox * oy);
                    end
                end
            end
        end

        % 3. Strong tether to (figX, figYPin) so the box stays right next to the anchor dot!
        nearX   = min(max(figX,    cx), cx + boxW);
        nearY   = min(max(figYPin, cy), cy + boxH);
        distPen = 450.0 * hypot(nearX - figX, nearY - figYPin);

        totalScore = ribPen + lblPen + oobPen + distPen;
        if totalScore < bestScore
            bestScore = totalScore;
            boxX      = cx;
            boxY      = cy;
        end
    end
end

figBoxAttachX  = min(max(figX,    boxX), boxX + boxW);
figBoxAttachY  = min(max(figYPin, boxY), boxY + boxH);
boxAnchorAxesX = toAxX(figBoxAttachX);
boxAnchorAxesY = toAxY(figBoxAttachY);
end

%% ========================================================================
%  ALIGN TOP & BOTTOM SURFACE RAILS TO IDENTICAL X GRID FOR TRUE CENTERLINE
%  ========================================================================
function [xc, yt, yb, yc, px, py, cProfile] = getTrueAlignedRibbonRails(hP)
% Uses SSankey's native 2xN normal cross-sections directly (NO interp1!):
% At every column c = 1..N, (X(1,c), Y(1,c)) and (X(2,c), Y(2,c)) are the two
% opposite edges of slice c, so their midpoint (xc(c), yc(c)) is ALWAYS dead-center
% inside the ribbon!

X  = double(hP.XData);
Y  = double(hP.YData);
CD = double(hP.CData);

if size(X, 1) == 2 && size(X, 2) > 1
    x1 = X(1, :);  y1 = Y(1, :);
    x2 = X(2, :);  y2 = Y(2, :);
    nPts = size(X, 2);
elseif size(X, 2) == 2 && size(X, 1) > 1
    x1 = X(:, 1)'; y1 = Y(:, 1)';
    x2 = X(:, 2)'; y2 = Y(:, 2)';
    nPts = size(X, 1);
else
    xv = X(:)';    yv = Y(:)';
    nHalf = floor(numel(xv) / 2);
    x1 = xv(1:nHalf);             y1 = yv(1:nHalf);
    x2 = fliplr(xv(nHalf+1:end)); y2 = fliplr(yv(nHalf+1:end));
    nPts = nHalf;
end

cProfile = repmat([0.25, 0.50, 0.65], nPts, 1);
if ndims(CD) == 3 && size(CD, 3) == 3
    if size(CD, 2) == nPts
        cProfile = squeeze(mean(CD, 1, 'omitnan'));
    elseif size(CD, 1) == nPts
        cProfile = squeeze(mean(CD, 2, 'omitnan'));
    end
end

px = [x1, fliplr(x2), x1(1)]';
py = [y1, fliplr(y2), y1(1)]';

% Exact cross-section center and top/bottom envelope at slice c = 1..nPts
xc = 0.5 * (x1 + x2);
yc = 0.5 * (y1 + y2);
yt = max(y1, y2);
yb = min(y1, y2);
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

function rgb = getBlockRGB(SK, bIdx)
rgb = [0.30, 0.50, 0.60];
try
    if isprop(SK, 'ColorList') && size(SK.ColorList, 1) >= bIdx
        rgb = double(SK.ColorList(bIdx, 1:3));
        return;
    end
    if isgraphics(SK.BlockHdl(bIdx))
        fc = SK.BlockHdl(bIdx).FaceColor;
        if isnumeric(fc) && numel(fc) == 3
            rgb = double(fc(:)');
        end
    end
catch
end
end
