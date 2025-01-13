function fixMuscleMappings(folderStruct, folderName, interName)
    currentFix = folderStruct.(folderName).(interName).loadedDelsys;
    tasks = fieldnames(currentFix);

    for r = 1:length(tasks)
        RVL = currentFix.(tasks{r}).RTA;
        LHAM = currentFix.(tasks{r}).RVL;
        LRF = currentFix.(tasks{r}).LHAM;
        LMG = currentFix.(tasks{r}).LRF;
        LTA = currentFix.(tasks{r}).LMG;
        LVL = currentFix.(tasks{r}).LTA;
        RTA = currentFix.(tasks{r}).LVL;

        % Update the corrected fields in folderStruct
        folderStruct.(folderName).(interName).loadedDelsys.(tasks{r}).RVL = RVL;
        folderStruct.(folderName).(interName).loadedDelsys.(tasks{r}).LHAM = LHAM;
        folderStruct.(folderName).(interName).loadedDelsys.(tasks{r}).LRF = LRF;
        folderStruct.(folderName).(interName).loadedDelsys.(tasks{r}).LMG = LMG;
        folderStruct.(folderName).(interName).loadedDelsys.(tasks{r}).LTA = LTA;
        folderStruct.(folderName).(interName).loadedDelsys.(tasks{r}).LVL = LVL;
        folderStruct.(folderName).(interName).loadedDelsys.(tasks{r}).RTA = RTA;
    end
end