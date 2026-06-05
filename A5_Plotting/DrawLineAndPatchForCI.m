function [PatchHandle] = DrawLineAndPatchForCI(tabToPlot,Xvar_line,Yvar_line,LineClr,Xvar_patch,Yvar_patch1,Yvar_patch2,NameValStruct)
%This function draws the shaded patch indicating CIs. Returns patch handle
% Inputs: - tabToPlot is the table which containes the details to plot. 
         %- Xvar_line,Yvar_line: variable names for the x and y co-ords for the line (beta values)
         %- LineClr: line colour for the line above
         %- Xvar_patch,Yvar_patch1,Yvar_patch2: variable names for the patch
         %- NameValStruct containes inputs for name-value argument.

    X_patch = [tabToPlot.(Xvar_patch); flip(tabToPlot.(Xvar_patch))]; %gets. X values for patch. The boundaries of the patch are plotted in the order they are input-ed. So,
    % here, the boundaries would be the x values for the line and then that reversed (because if the second half is in the same order, then the last point of the bottom 
    % boundary would be connected diagonally to teh first point in the top boundary).
    Y_patch = [tabToPlot.(Yvar_patch1); flip(tabToPlot.(Yvar_patch2))]; %Similarly for the Y coords of the patch--gotta match it to the order of the X coords of patch
    plot(tabToPlot.(Xvar_line),tabToPlot.(Yvar_line),'Color',LineClr,'LineWidth',1) %plot line
    PatchHandle = patch(X_patch,Y_patch,NameValStruct.FaceClr,'FaceColor',NameValStruct.FaceClr,'FaceAlpha',NameValStruct.FaceAlphaVal,'EdgeColor',NameValStruct.EdgeClr,...
        'EdgeAlpha',NameValStruct.EdgeAlphaVal); %Make patc h
end