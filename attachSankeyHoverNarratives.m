function attachSankeyHoverNarratives(axHdl, SK, linksCell, narrativeMap, valFmtStr)
% attachSankeyHoverNarratives Interactive click & arrow-key narrative inspector for SSankey
%
%   - Click any ribbon to spotlight it, bold its Source & Target block legends,
%     place an anchor dot dead-center on the ribbon, and display the policy narrative.
%   - Up/Down Arrow Keys: Traverse ribbons in strict 2-level Gate -> Block hierarchy.
%   - Left/Right Arrow Keys: Switch the anchor between Source (Left) and Target (Right) block.
%   - Click background or press Esc to clear selection.

if nargin < 5 || isempty(valFmtStr)
    valFmtStr = '%.2f';
end
if isempty(axHdl) || ~isgraphics(axHdl)
    return;
end
figHdl = ancestor(axHdl, 'figure');
if isempty(figHdl) || ~isgraphics(figHdl)
    return;
end

% 1. Disable default axes interactivity/toolbars that can intercept mouse clicks
try
    disableDefaultInteractivity(axHdl);
    axHdl.Toolbar.Visible = 'off';
    axHdl.Interactions = [];
catch
end

% 2. Clean up built-in MATLAB DataTips, AnnotationPane objects, & prior overlays
nukeAllDataTips(figHdl, axHdl);
delete(findall(figHdl, 'Tag', 'SSankeyHoverBox'));
delete(findall(axHdl,  'Tag', 'SSankeyLeaderLine'));
delete(findall(axHdl,  'Tag', 'SSankeyAnchorDot'));
delete(findall(axHdl,  'Tag', 'SSankeyThinSpine'));

% Make all child objects click-transparent AND also wire their ButtonDownFcn
% directly to onFigureClick so even if an object intercepts a click, it still fires!
allObjs = findall(figHdl);
for m = 1:numel(allObjs)
    obj = allObjs(m);
    if obj ~= figHdl && obj ~= axHdl
        try if isprop(obj, 'Interactions'),   obj.Interactions   = [];     end; catch, end
        try if isprop(obj, 'PickableParts'),  obj.PickableParts  = 'none'; end; catch, end
        try if isprop(obj, 'HitTest'),        obj.HitTest        = 'off';  end; catch, end
        try if isprop(obj, 'ButtonDownFcn'),  obj.ButtonDownFcn  = @onFigureClick; end; catch, end
        try
            if isprop(obj, 'DataTipTemplate') && ~isempty(obj.DataTipTemplate)
                obj.DataTipTemplate.DataTipRows = [];
            end
        catch
        end
    end
end
axHdl.HitTest       = 'on';
axHdl.PickableParts = 'all';
axHdl.ButtonDownFcn = @onFigureClick;

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
blkLblHdl     = gobjects(nBlocks, 1);
origLblWeight = cell(nBlocks, 1);
origLblSize   = zeros(nBlocks, 1);
origLblColor  = cell(nBlocks, 1);
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
        % Use the EXACT rendered Extent [xLeft, yBottom, width, height] of block b's label!
        extB = double(blkLblHdl(b).Extent);
        if numel(extB) == 4 && extB(3) > 0
            lblBBox(b, :) = [extB(1), extB(1) + extB(3), extB(2), extB(2) + extB(4)];
        end
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
rawX1      = cell(1, nLinks);
rawY1      = cell(1, nLinks);
rawX2      = cell(1, nLinks);
rawY2      = cell(1, nLinks);
ribThick   = zeros(nLinks, 1);
rgbStrip   = cell(1, nLinks);
bbox       = zeros(nLinks, 4);
linkSrcBlk = zeros(nLinks, 1);
linkTgtBlk = zeros(nLinks, 1);
linkRow    = (1:nLinks)';

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

        [xg, yt, yb, ym, x1, y1, x2, y2, cProfile] = getTrueAlignedRibbonRails(hP);
        xGrid{k}    = xg;
        yTopGrid{k} = yt;
        yBotGrid{k} = yb;
        yMidGrid{k} = ym;
        rawX1{k}    = x1;
        rawY1{k}    = y1;
        rawX2{k}    = x2;
        rawY2{k}    = y2;
        ribThick(k) = median(yt - yb);
        rgbStrip{k} = cProfile;
        bbox(k, :)  = [min([x1(:); x2(:)]), max([x1(:); x2(:)]), ...
            min([y1(:); y2(:)]), max([y1(:); y2(:)])];

        if k <= numel(sIndVec) && sIndVec(k) > 0 && tIndVec(k) > 0
            sBlk = sIndVec(k);
            tBlk = tIndVec(k);
            linkSrcBlk(k) = sBlk;
            linkTgtBlk(k) = tBlk;

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

% 5. Create Leader Line + Center Anchor Dot + Native Axes Text Callout Box
%    (Using native axes text() instead of annotation('textbox') avoids MATLAB's
%    AnnotationPane overlay layer, which can block mouse clicks in the middle of the figure!)
hold(axHdl, 'on');
leaderHdl = plot(axHdl, nan, nan, ':', ...
    'Tag',           'SSankeyLeaderLine', ...
    'LineWidth',     1.6, ...
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
hoverBox = text(axHdl, 0, 0, '', ...
    'Tag',                 'SSankeyHoverBox', ...
    'Units',               'data', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment',   'bottom', ...
    'FontName',            'Helvetica', ...
    'FontSize',            8.4, ...
    'Color',               [0.08, 0.08, 0.10], ...
    'BackgroundColor',     [0.98, 0.99, 1.00], ...
    'EdgeColor',           [0.20, 0.45, 0.65], ...
    'LineWidth',           1.5, ...
    'Margin',              4.0, ...
    'Interpreter',         'none', ...
    'Clipping',            'off', ...
    'HitTest',             'off', ...
    'PickableParts',       'none', ...
    'Visible',             'off');

% 6. Interactive State Variables
activeIdx  = 0;
anchorBlk  = 1;
anchorSide = 'src'; % 'src' (Left) or 'tgt' (Right)

figHdl.WindowButtonDownFcn = @onFigureClick;
figHdl.WindowKeyPressFcn   = @onKeyPress;

% =====================================================================
%  MOUSE CLICK CALLBACK
% =====================================================================
    function onFigureClick(~, ~)
        nukeAllDataTips(figHdl, axHdl);
        if ~isgraphics(axHdl), return; end

        % Convert figHdl.CurrentPoint directly into axes data coordinates (mx, my)
        oldFigU = figHdl.Units;
        oldAxU  = axHdl.Units;
        figHdl.Units = 'normalized';
        axHdl.Units  = 'normalized';
        fpt   = figHdl.CurrentPoint;
        axPos = axHdl.Position;
        figHdl.Units = oldFigU;
        axHdl.Units  = oldAxU;

        xl = axHdl.XLim;
        yl = axHdl.YLim;
        mx = xl(1) + ((fpt(1) - axPos(1)) / axPos(3)) * diff(xl);
        my = yl(1) + ((fpt(2) - axPos(2)) / axPos(4)) * diff(yl);

        if mx < xl(1) || mx > xl(2) || my < yl(1) || my > yl(2)
            clearSelection();
            return;
        end

        % 1. Check if user clicked directly on a Node Block bar
        for b = 1:nBlocks
            if ~isnan(blkBBox(b, 1)) && ...
                    mx >= blkBBox(b, 1) - 0.02 && mx <= blkBBox(b, 2) + 0.02 && ...
                    my >= blkBBox(b, 3)        && my <= blkBBox(b, 4)
                outLinks = find(linkSrcBlk == b);
                inLinks  = find(linkTgtBlk == b);
                if ~isempty(outLinks)
                    anchorBlk  = b;
                    anchorSide = 'src';
                    [~, bestR] = min(abs(cellfun(@(v) v(1), yMidGrid(outLinks)) - my));
                    chosenIdx  = outLinks(bestR);
                    xg = xGrid{chosenIdx};
                    selectRibbon(chosenIdx, xg(round(0.28 * numel(xg))));
                    return;
                elseif ~isempty(inLinks)
                    anchorBlk  = b;
                    anchorSide = 'tgt';
                    [~, bestR] = min(abs(cellfun(@(v) v(end), yMidGrid(inLinks)) - my));
                    chosenIdx  = inLinks(bestR);
                    xg = xGrid{chosenIdx};
                    selectRibbon(chosenIdx, xg(round(0.72 * numel(xg))));
                    return;
                end
            end
        end

        % 2. Test all ribbons using BOTH independent-rail vertical slice bounds
        %    AND quad-by-quad segment containment (immune to normal-tilt shear!)
        candidates = [];
        relDistMid = [];
        hitPad     = 0.008 * diff(yl);

        for idx = 1:nLinks
            if mx >= bbox(idx, 1) - 0.03 && mx <= bbox(idx, 2) + 0.03 && ...
                    my >= bbox(idx, 3) - hitPad && my <= bbox(idx, 4) + hitPad

                xg = xGrid{idx};
                yt = yTopGrid{idx};
                yb = yBotGrid{idx};
                ym = yMidGrid{idx};
                [~, cNearest] = min(abs(xg - mx));

                % Check 1: Aligned vertical slice [yb(cNearest), yt(cNearest)] at mx
                isHit = (mx >= xg(1) - 0.02 && mx <= xg(end) + 0.02) && ...
                    (my >= yb(cNearest) - hitPad && my <= yt(cNearest) + hitPad);

                % Check 2: Direct quad-strip check on raw (x1,y1)-(x2,y2) mesh
                if ~isHit
                    isHit = isPointInRibbonMesh(mx, my, rawX1{idx}, rawY1{idx}, rawX2{idx}, rawY2{idx}, hitPad);
                end

                if isHit
                    candidates(end+1) = idx; %#ok<AGROW>
                    halfH = max(0.5 * (yt(cNearest) - yb(cNearest)), hitPad);
                    relDistMid(end+1) = abs(my - ym(cNearest)) / halfH; %#ok<AGROW>
                end
            end
        end

        if isempty(candidates)
            clearSelection();
            return;
        end

        [~, bestPos] = min(relDistMid);
        hitIdx = candidates(bestPos);

        % Set anchor block (Left/Source vs Right/Target) based on click X position:
        % Default to left-to-right flow ('src') unless the click is clearly in
        % the rightmost 40% of the ribbon (fracX > 0.60)!
        xg    = xGrid{hitIdx};
        fracX = (mx - xg(1)) / max(1e-8, xg(end) - xg(1));
        if fracX <= 0.60
            anchorSide = 'src';
            anchorBlk  = linkSrcBlk(hitIdx);
            % If clicked near the middle, pull the dot slightly left of center
            % so it visually signals Left/Source tracking
            pinX = min(mx, xg(1) + 0.35 * (xg(end) - xg(1)));
        else
            anchorSide = 'tgt';
            anchorBlk  = linkTgtBlk(hitIdx);
            pinX = max(mx, xg(1) + 0.65 * (xg(end) - xg(1)));
        end

        % Note: Clicking a new spot on the ALREADY active ribbon now moves the
        % anchor pin to your new click spot instead of turning the ribbon off!
        selectRibbon(hitIdx, pinX);
    end

% =====================================================================
%  KEYBOARD ARROW-KEY NAVIGATION (STRICT 2-LEVEL GATE->BLOCK HIERARCHY)
% =====================================================================
    function onKeyPress(~, evt)
        if strcmp(evt.Key, 'escape')
            clearSelection();
            return;
        end
        if activeIdx == 0 || ~isgraphics(axHdl), return; end

        switch evt.Key
            case {'uparrow', 'downarrow'}
                % 1. Outer Hierarchy: All blocks in the current Gate column, sorted bottom-to-top
                currGate = blkGateCol(anchorBlk);
                gateBlks = find(blkGateCol == currGate);
                [~, blkOrd] = sort(blkYMid(gateBlks), 'ascend');
                gateBlks = gateBlks(blkOrd);

                % 2. Inner Hierarchy: Within each block b in this Gate, sort its ribbons
                %    by the vertical height (blkYMid) of the partner block at the other end!
                hierLinks = [];
                for bIdx = 1:numel(gateBlks)
                    b = gateBlks(bIdx);
                    if strcmp(anchorSide, 'src')
                        bLinks = find(linkSrcBlk == b);
                        [~, partnerOrd] = sort(blkYMid(linkTgtBlk(bLinks)), 'ascend');
                    else
                        bLinks = find(linkTgtBlk == b);
                        [~, partnerOrd] = sort(blkYMid(linkSrcBlk(bLinks)), 'ascend');
                    end
                    hierLinks = [hierLinks; bLinks(partnerOrd(:))]; %#ok<AGROW>
                end

                if numel(hierLinks) <= 1, return; end
                currPos = find(hierLinks == activeIdx, 1);
                if isempty(currPos), currPos = 1; end

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

            case 'leftarrow'
                anchorSide = 'src';
                anchorBlk  = linkSrcBlk(activeIdx);
                xg = xGrid{activeIdx};
                selectRibbon(activeIdx, xg(min(numel(xg), max(1, round(0.28 * numel(xg))))));

            case 'rightarrow'
                anchorSide = 'tgt';
                anchorBlk  = linkTgtBlk(activeIdx);
                xg = xGrid{activeIdx};
                selectRibbon(activeIdx, xg(min(numel(xg), max(1, round(0.72 * numel(xg))))));
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
                    blkLblHdl(b).Color      = 0.75 * origLblColor{b} + 0.25 * [1, 1, 1];
                end
            end
        end

        % 2. Find slice sIdx on the aligned X grid
        xg = xGrid{hitIdx};
        yt = yTopGrid{hitIdx};
        yb = yBotGrid{hitIdx};
        ym = yMidGrid{hitIdx};
        N  = numel(xg);

        [~, sIdx] = min(abs(xg - refX));
        iMin = max(2, round(0.16 * N));
        iMax = min(N - 1, round(0.84 * N));
        sIdx = min(max(sIdx, iMin), iMax);

        xPin    = xg(sIdx);
        yTopLoc = yt(sIdx);
        yBotLoc = yb(sIdx);
        yMidLoc = ym(sIdx);

        cProfile = rgbStrip{hitIdx};
        cLocal   = cProfile(min(sIdx, size(cProfile, 1)), :);
        cBorder  = max(0, min(1, 0.78 * cLocal));
        cTintBg  = 0.91 * [1, 1, 1] + 0.09 * cLocal;

        if ribThick(hitIdx) < 0.025 * diff(axHdl.YLim)
            SK.LinkHdl(hitIdx).FaceAlpha = 1.0;
        end

        % 3. Build Narrative + Anchor status text (wrapped for a compact, squarer box)
        rowK     = linkRow(hitIdx);
        srcLabel = strrep(char(linksCell{rowK, 1}), newline, ' ');
        tgtLabel = strrep(char(linksCell{rowK, 2}), newline, ' ');
        flowVal  = linksCell{rowK, 3};

        sNum = extractNodeNumber(srcLabel);
        tNum = extractNodeNumber(tgtLabel);

        % Look up narrative in containers.Map ('18->24') OR struct ('n_18_24')
        narEntry = [];
        keyArrow = sprintf('%d->%d', sNum, tNum);
        keyUnder = sprintf('n_%d_%d', sNum, tNum);
        if isa(narrativeMap, 'containers.Map')
            if isKey(narrativeMap, keyArrow)
                narEntry = narrativeMap(keyArrow);
            elseif isKey(narrativeMap, sprintf('%d_%d', sNum, tNum))
                narEntry = narrativeMap(sprintf('%d_%d', sNum, tNum));
            end
        elseif isstruct(narrativeMap) && isfield(narrativeMap, keyUnder)
            narEntry = narrativeMap.(keyUnder);
        end

        wrapW   = 56; % Compact, square width now that the wide [Anchor: ...] line is gone!
        hdrLine = wrapTextWithIndent(sprintf('[%s]  -->  [%s]', srcLabel, tgtLabel), wrapW, '', '    ');

        if ~isempty(narEntry)
            if isstruct(narEntry)
                tStr = ''; mStr = ''; cStr = '';
                if isfield(narEntry, 'title'),     tStr = strtrim(char(narEntry.title));     end
                if isfield(narEntry, 'mechanism'), mStr = strtrim(char(narEntry.mechanism)); end
                if isfield(narEntry, 'citation'),  cStr = strtrim(char(narEntry.citation));  end

                if ~isempty(tStr)
                    flowStr = sprintf('• Flow: %s  |  %s', sprintf(valFmtStr, flowVal), tStr);
                else
                    flowStr = sprintf('• Flow: %s', sprintf(valFmtStr, flowVal));
                end
                flowLine  = wrapTextWithIndent(flowStr, wrapW, '  ', '    ');
                mechLines = wrapTextWithIndent(sprintf('• Mechanism: %s', mStr), wrapW, '  ', '    ');
                citLines  = formatCitationLines(cStr);
                boxLines  = [hdrLine, flowLine, mechLines, citLines];
            else
                if iscell(narEntry)
                    rawLines = cellstr(string(narEntry(:)))';
                else
                    rawLines = cellstr(splitlines(string(narEntry)))';
                end
                flowLine  = {sprintf('  • Flow: %s', sprintf(valFmtStr, flowVal))};
                bodyLines = {};
                for rL = 1:numel(rawLines)
                    lin = strtrim(rawLines{rL});
                    if isempty(lin), continue; end
                    if contains(lin, 'Citation:', 'IgnoreCase', true) || contains(lin, 'Ref:', 'IgnoreCase', true)
                        cClean = regexprep(lin, '^[•\-\s]*(Citation|Ref|References)\s*:\s*', '', 'ignorecase');
                        bodyLines = [bodyLines, formatCitationLines(cClean)]; %#ok<AGROW>
                    else
                        bodyLines = [bodyLines, wrapTextWithIndent(lin, wrapW, '  ', '    ')]; %#ok<AGROW>
                    end
                end
                boxLines = [hdrLine, flowLine, bodyLines];
            end
        else
            flowLine = {sprintf('  • Flow: %s   |   Node %d -> Node %d', sprintf(valFmtStr, flowVal), sNum, tNum)};
            boxLines = [hdrLine, flowLine];
        end

        hoverBox.String          = strjoin(boxLines, newline);
        hoverBox.BackgroundColor = cTintBg;
        hoverBox.EdgeColor       = cBorder;
        hoverBox.Visible         = 'on';
        drawnow limitrate;

        % Measure exact width & height of hoverBox in normalized figure units
        extAx = double(hoverBox.Extent); % [x, y, w, h] in axes data units
        oldUnits = axHdl.Units;
        axHdl.Units = 'normalized';
        axPos = axHdl.Position;
        axHdl.Units = oldUnits;

        xl = axHdl.XLim;
        yl = axHdl.YLim;
        boxW = (extAx(3) / diff(xl)) * axPos(3) + 0.008;
        boxH = (extAx(4) / diff(yl)) * axPos(4) + 0.008;

        [boxX, boxY, boxAnchorAxesX, boxAnchorAxesY] = ...
            computeFullSpanBoxAndCenterPin(axHdl, xPin, yBotLoc, yTopLoc, xg, yb, yt, ...
            boxW, boxH, blkBBox, lblBBox, sBlkAct, tBlkAct);

        % Position the axes text box at the computed data coordinates (axBoxX, axBoxY)
        axBoxX = xl(1) + ((boxX - axPos(1)) / axPos(3)) * diff(xl);
        axBoxY = yl(1) + ((boxY - axPos(2)) / axPos(4)) * diff(yl);
        hoverBox.Position = [axBoxX, axBoxY, 0];

        set(leaderHdl, ...
            'XData',   [xPin, boxAnchorAxesX], ...
            'YData',   [yMidLoc, boxAnchorAxesY], ...
            'Color',   cBorder, ...
            'Visible', 'on');
        set(dotHdl, ...
            'XData',           xPin, ...
            'YData',           yMidLoc, ...
            'MarkerFaceColor', [1, 1, 1], ...
            'MarkerEdgeColor', cBorder, ...
            'Visible',         'on');

        % Keep dotHdl, leaderHdl, and hoverBox at the very top of the axes visual stack
        uistack(leaderHdl, 'top');
        uistack(dotHdl,    'top');
        uistack(hoverBox,  'top');
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

% =========================================================================
%  HELPER 1: INDEPENDENT-RAIL VERTICAL SLICE ENVELOPE (NO SHEAR DEAD ZONES)
% =========================================================================
function [xc, yt, yb, yc, x1, y1, x2, y2, cProfile] = getTrueAlignedRibbonRails(hP)
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

xL = min([x1(:); x2(:)]);
xR = max([x1(:); x2(:)]);
xc = linspace(xL, xR, nPts);

% Evaluate Rail 1 and Rail 2 at the SAME horizontal coordinate xc(k)
% using linear segment interpolation along each rail independently!
y1AtXc = evalRailAtX(x1, y1, xc);
y2AtXc = evalRailAtX(x2, y2, xc);

yt = max(y1AtXc, y2AtXc);
yb = min(y1AtXc, y2AtXc);
yc = 0.5 * (yt + yb);
end

function yOut = evalRailAtX(xr, yr, xQuery)
% Finds all segment crossings of polyline (xr, yr) at each xQuery(k)
yOut = zeros(size(xQuery));
for k = 1:numel(xQuery)
    xq = xQuery(k);
    [~, iNear] = min(abs(xr - xq));
    yOut(k) = yr(iNear);
end
end

function isIn = isPointInRibbonMesh(mx, my, x1, y1, x2, y2, hitPad)
% Checks if (mx, my) lies inside ANY quad strip [c, c+1] of the 2xN Surface mesh
isIn = false;
nSeg = numel(x1) - 1;
for c = 1:nSeg
    qx = [x1(c), x1(c+1), x2(c+1), x2(c)];
    qy = [y1(c), y1(c+1), y2(c+1), y2(c)];
    if mx >= min(qx) - 0.01 && mx <= max(qx) + 0.01 && ...
            my >= min(qy) - hitPad && my <= max(qy) + hitPad
        if inpolygon(mx, my, qx, qy)
            isIn = true;
            return;
        end
    end
end
end

% =========================================================================
%  HELPER 2: REGIME-AWARE BOX PLACEMENT WITH TRUE BOX EXTENT & LABEL HALO
% =========================================================================
function [boxX, boxY, boxAnchorAxesX, boxAnchorAxesY] = ...
    computeFullSpanBoxAndCenterPin(axHdl, xPin, yBotLoc, yTopLoc, xg, yBotVec, yTopVec, ...
    boxW, boxH, ~, ~, sBlk, tBlk)

oldUnits = axHdl.Units;
axHdl.Units = 'normalized';
axPos = axHdl.Position;
axHdl.Units = oldUnits;

xl = axHdl.XLim;
yl = axHdl.YLim;

toFigX = @(axX) axPos(1) + ((axX - xl(1)) ./ diff(xl)) .* axPos(3);
toFigY = @(axY) axPos(2) + ((axY - yl(1)) ./ diff(yl)) .* axPos(4);
toAxX  = @(fgX) xl(1) + ((fgX - axPos(1)) ./ axPos(3)) .* diff(xl);
toAxY  = @(fgY) yl(1) + ((fgY - axPos(2)) ./ axPos(4)) .* diff(yl);

figX    = toFigX(xPin);
figYPin = toFigY(0.5 * (yBotLoc + yTopLoc));

% Hard floor above the bottom J = 1..16 axis line & stage labels
minX = 0.025; maxX = 0.985;
minY = 0.225; maxY = 0.925;

% Read the EXACT rendered Extent of every visible text label on the axes
% (above the bottom J-axis line) so NO label can ever be covered!
figLbls = zeros(0, 4);
allTxts = findall(axHdl, 'Type', 'text', 'Visible', 'on');
for t = 1:numel(allTxts)
    tx = allTxts(t);
    if ~strcmp(tx.Tag, 'SSankeyHoverBox') && strcmpi(tx.Units, 'data')
        ext = double(tx.Extent); % [xLeft, yBottom, width, height] in axes units
        if numel(ext) == 4 && ext(3) > 0 && ext(2) > yl(1) + 0.16 * diff(yl)
            figLbls(end+1, :) = [toFigX(ext(1)), toFigX(ext(1) + ext(3)), ...
                toFigY(ext(2)), toFigY(ext(2) + ext(4))]; %#ok<AGROW>
        end
    end
end

xMidRib   = 0.5 * (xg(1) + xg(end));
isFates17 = (xl(2) < 6.8); % 5-Gate Fates has xl(2) ~ 6.31; 6-Gate Fiscal has xl(2) ~ 7.38

if ~isFates17
    % -----------------------------------------------------------------
    %  CASE A: 6-GATE FISCAL SANKEY (OPPOSITE SIDE OF GATE-4 WIGGLY LINE)
    % -----------------------------------------------------------------
    if xMidRib >= 4.0
        % Active ribbon is on the RIGHT (G4->G5 or G5->G6) -> Park box on LEFT of Gate 4
        maxLeftEdge = toFigX(3.72) - boxW;
        candX = unique(min(max([ ...
            maxLeftEdge, ...
            toFigX(3.45) - boxW, ...
            toFigX(2.88) - boxW, ...
            toFigX(2.15), ...
            toFigX(1.15) ...
            ], minX), maxLeftEdge));
    else
        % Active ribbon is on the LEFT (G1..G4) -> Park box on RIGHT of Gate 4
        minRightEdge = toFigX(4.30);
        candX = unique(min(max([ ...
            minRightEdge, ...
            toFigX(4.55), ...
            toFigX(5.12), ...
            toFigX(6.10), ...
            maxX - boxW ...
            ], minRightEdge), maxX - boxW));
    end
else
    % -----------------------------------------------------------------
    %  CASE B: 5-GATE CHILD FATES SANKEY
    % -----------------------------------------------------------------
    if xMidRib < 3.9
        % First three ribbon stages (G1->G2, G2->G3, G3->G4):
        % Offer the open right-hand bay of Node 16/Gate 4-5 FIRST, plus Node 2's open bays
        candX = unique(min(max([ ...
            toFigX(4.35), ...
            toFigX(4.90) - boxW, ...
            toFigX(5.10), ...
            maxX - boxW, ...
            toFigX(1.15), ...
            toFigX(2.15) ...
            ], minX), maxX - boxW));
    else
        % Last ribbon stage (G4->G5, e.g. 11->16, 11->17, 9->15):
        % Offer:
        %   1) Right of Node 16 bar (toFigX(5.09) .. maxX - boxW), above or below Node 16's label
        %   2) Inside the G4->G5 bay (toFigX(4.35) .. toFigX(4.92) - boxW), above/below active ribbon
        %   3) Inside Node 2's open G1->G2 or G2->G3 bay (toFigX(1.15), toFigX(2.15)) if G4->G5 is full!
        candX = unique(min(max([ ...
            toFigX(5.09), ...
            maxX - boxW, ...
            toFigX(4.90) - boxW, ...
            toFigX(4.35), ...
            toFigX(2.15), ...
            toFigX(1.15) ...
            ], minX), maxX - boxW));
    end
end

candY = unique(min(max([ ...
    figYPin - 0.50 * boxH, ...
    linspace(minY, maxY - boxH, 45) ...
    ], minY), maxY - boxH));

bestScore = inf;
boxX      = candX(1);
boxY      = min(max(figYPin - 0.50 * boxH, minY), maxY - boxH);

% Mandatory breathing-room halo around every text label (~14 px vertically, ~16 px horizontally)
padX = 0.012;
padY = 0.016;

for c = 1:numel(candX)
    cx       = candX(c);
    xAx1     = toAxX(cx);
    xAx2     = toAxX(cx + boxW);
    fullSpan = (xg >= xAx1) & (xg <= xAx2);

    for s = 1:numel(candY)
        cy = candY(s);

        % 1. Strictly avoid covering the active ribbon itself
        ribPen = 0;
        if any(fullSpan)
            idxSpan = find(fullSpan);
            for ii = idxSpan(:)'
                sTop = toFigY(yTopVec(ii)) + 0.010;
                sBot = toFigY(yBotVec(ii)) - 0.010;
                ovSlice = max(0, min(cy + boxH, sTop) - max(cy, sBot));
                if ovSlice > 0
                    ribPen = ribPen + 1500 + 120000 * ovSlice;
                end
            end
        end

        % 2. Strictly avoid covering ANY text label on the axes (with padX, padY halo)
        lblPen = 0;
        for b = 1:size(figLbls, 1)
            ox = max(0, min(cx + boxW, figLbls(b, 2) + padX) - max(cx, figLbls(b, 1) - padX));
            oy = max(0, min(cy + boxH, figLbls(b, 4) + padY) - max(cy, figLbls(b, 3) - padY));
            if ox > 0 && oy > 0
                lblPen = lblPen + 900 + 180000 * (ox * oy);
            end
        end

        % 3. Avoid straddling across an internal Gate bar (Gates 2, 3, 4)
        barPen = 0;
        for gBar = 2:4
            if xAx1 < gBar + 0.06 && xAx2 > gBar - 0.06
                barPen = barPen + 250;
            end
        end

        boxMidY = cy + 0.50 * boxH;
        boxMidX = cx + 0.50 * boxW;
        distPen = 35.0 * abs(boxMidY - figYPin) + 14.0 * abs(boxMidX - figX);

        totalScore = ribPen + lblPen + barPen + distPen;
        if totalScore < bestScore
            bestScore = totalScore;
            boxX      = cx;
            boxY      = cy;
        end
    end
end

% Attach the dotted leader line to the point on the box border closest to (figX, figYPin)
figBoxAttachX  = min(max(figX,    boxX), boxX + boxW);
figBoxAttachY  = min(max(figYPin, boxY), boxY + boxH);
boxAnchorAxesX = toAxX(figBoxAttachX);
boxAnchorAxesY = toAxY(figBoxAttachY);
end

function wrappedCell = wrapTextWithIndent(strIn, maxChars, firstIndent, contIndent)
% Flows prose text into multiple lines of <= maxChars without breaking words
words = strsplit(strtrim(char(strIn)), ' ');
wrappedCell = {};
currLine = firstIndent;
for w = 1:numel(words)
    wd = words{w};
    if isempty(wd), continue; end
    if numel(currLine) > numel(firstIndent) && (numel(currLine) + 1 + numel(wd) > maxChars)
        wrappedCell{end+1} = currLine; %#ok<AGROW>
        currLine = [contIndent, wd];
    else
        if numel(currLine) == numel(firstIndent) || numel(currLine) == numel(contIndent)
            currLine = [currLine, wd]; %#ok<AGROW>
        else
            currLine = [currLine, ' ', wd]; %#ok<AGROW>
        end
    end
end
if ~isempty(strtrim(currLine))
    wrappedCell{end+1} = currLine;
end
end

function citCell = formatCitationLines(citStr)
% Keeps a single citation on one unbroken line, but splits multiple ';'-separated
% citations onto individual indented lines so the box stays square & compact!
citStr = strtrim(char(citStr));
if isempty(citStr)
    citCell = {};
    return;
end
parts = strtrim(strsplit(citStr, ';'));
parts = parts(~cellfun(@isempty, parts));
if numel(parts) <= 1
    citCell = {sprintf('  • Citation: %s', parts{1})};
else
    citCell = cell(1, numel(parts));
    citCell{1} = sprintf('  • Citations: %s;', parts{1});
    for p = 2:numel(parts)
        sfx = ';';
        if p == numel(parts), sfx = ''; end
        citCell{p} = sprintf('      %s%s', parts{p}, sfx);
    end
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

function nukeAllDataTips(figHdl, axHdl)
try
    dcm = datacursormode(figHdl);
    dcm.Enable = 'off';
    dcm.removeAllDataCursors();
catch
end
try
    delete(findall(figHdl, 'Type', 'datatip'));
    delete(findall(axHdl,  'Type', 'datatip'));
    delete(findall(figHdl, 'Tag',  'DataTipMarker'));
catch
end
end

function num = extractNodeNumber(str)
tok = regexp(str, '^(\d+)\.', 'tokens', 'once');
if ~isempty(tok)
    num = str2double(tok{1});
else
    num = 0;
end
end