/**
 * CSV EXPORT - No size limits, handles unlimited items
 * Exports to a CSV file in your Drive instead of a spreadsheet
 * Perfect for huge folder structures (4000+ items)
 */

function exportDriveStructureToCSV() {
  // CONFIGURE: One folder at a time
  var folderId = '18L3pZf5qgxk4SfXJkNIne8grnQfjhEYa'; // Capital Project
  // var folderId = '15Wg2NPfuexpu4QfBk5F4PB7jbW3ZjUrC'; // Grants folder
  
  var startTime = new Date().getTime();
  
  try {
    var folder = DriveApp.getFolderById(folderId);
    var folderName = folder.getName();
    Logger.log('Starting CSV export of: ' + folderName);
    
    // Build CSV content in memory
    var csvContent = [];
    
    // Headers
    csvContent.push([
      'Item Type',
      'Name', 
      'Full Path',
      'Depth',
      'ID',
      'MIME Type',
      'Last Modified',
      'Size',
      'Parent Folder'
    ].join(','));
    
    // Add root folder
    var rootData = formatFolderDataCSV(folder, folderName, 0, folderName);
    csvContent.push(rootData);
    
    // Process all contents
    processFolderCSV(folder, folderName, 1, csvContent, startTime);
    
    // Join all lines
    var csvText = csvContent.join('\n');
    
    // Create CSV file in Drive
    var fileName = 'Drive_Export_' + folderName.replace(/[^a-z0-9]/gi, '_') + '_' + 
                   new Date().toISOString().split('T')[0] + '.csv';
    
    var blob = Utilities.newBlob(csvText, 'text/csv', fileName);
    var file = DriveApp.createFile(blob);
    
    var elapsedTime = ((new Date().getTime() - startTime) / 1000).toFixed(1);
    
    // Success message
    var message = 'CSV Export Complete!\n\n' +
                  'Total items: ' + (csvContent.length - 1) + '\n' +
                  'Time: ' + elapsedTime + ' seconds\n' +
                  'Folder: ' + folderName + '\n\n' +
                  'File created in your Drive:\n' + 
                  fileName + '\n\n' +
                  'Direct link:\n' + file.getUrl();
    
    Logger.log(message);
    Browser.msgBox('Success!', message, Browser.Buttons.OK);
    
    return file.getUrl();
    
  } catch (e) {
    Logger.log('Error: ' + e.message);
    Browser.msgBox('Error', e.message, Browser.Buttons.OK);
  }
}

/**
 * Recursively process folder contents for CSV
 */
function processFolderCSV(folder, pathPrefix, depth, csvContent, startTime) {
  // Check if we're approaching timeout (5 min limit)
  var elapsedTime = (new Date().getTime() - startTime) / 1000;
  if (elapsedTime > 300) { // 5 minutes
    Logger.log('WARNING: Approaching timeout at ' + csvContent.length + ' items');
    Browser.msgBox('Timeout Warning', 
                   'Script approaching 6-minute limit. Exported ' + csvContent.length + ' items so far.\n\n' +
                   'Consider breaking this into smaller subfolder exports.', 
                   Browser.Buttons.OK);
    return;
  }
  
  // Log progress every 500 items
  if (csvContent.length % 500 === 0) {
    Logger.log('Processed ' + csvContent.length + ' items... (' + elapsedTime.toFixed(1) + 's elapsed)');
  }
  
  // Process subfolders
  var folders = folder.getFolders();
  var folderList = [];
  
  while (folders.hasNext()) {
    folderList.push(folders.next());
  }
  
  for (var i = 0; i < folderList.length; i++) {
    var subfolder = folderList[i];
    var folderPath = pathPrefix + ' / ' + subfolder.getName();
    
    csvContent.push(formatFolderDataCSV(subfolder, folderPath, depth, pathPrefix));
    
    // Recurse
    processFolderCSV(subfolder, folderPath, depth + 1, csvContent, startTime);
  }
  
  // Process files
  var files = folder.getFiles();
  var fileList = [];
  
  while (files.hasNext()) {
    fileList.push(files.next());
  }
  
  for (var i = 0; i < fileList.length; i++) {
    var file = fileList[i];
    var filePath = pathPrefix + ' / ' + file.getName();
    
    csvContent.push(formatFileDataCSV(file, filePath, depth, pathPrefix));
  }
}

/**
 * Format folder data as CSV line
 */
function formatFolderDataCSV(folder, path, depth, parentPath) {
  return [
    'Folder',
    csvEscape(folder.getName()),
    csvEscape(path),
    depth,
    folder.getId(),
    'application/vnd.google-apps.folder',
    folder.getLastUpdated().toISOString(),
    '',
    csvEscape(parentPath)
  ].join(',');
}

/**
 * Format file data as CSV line
 */
function formatFileDataCSV(file, path, depth, parentPath) {
  var size = file.getSize();
  return [
    'File',
    csvEscape(file.getName()),
    csvEscape(path),
    depth,
    file.getId(),
    csvEscape(file.getMimeType()),
    file.getLastUpdated().toISOString(),
    formatBytes(size),
    csvEscape(parentPath)
  ].join(',');
}

/**
 * Escape CSV values (handle commas and quotes)
 */
function csvEscape(value) {
  if (value === null || value === undefined) return '';
  var str = value.toString();
  if (str.indexOf(',') >= 0 || str.indexOf('"') >= 0 || str.indexOf('\n') >= 0) {
    return '"' + str.replace(/"/g, '""') + '"';
  }
  return str;
}

/**
 * Format bytes
 */
function formatBytes(bytes) {
  if (bytes === 0 || bytes === '') return '';
  var k = 1024;
  var sizes = ['Bytes', 'KB', 'MB', 'GB'];
  var i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

/**
 * Menu
 */
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('📁 CSV Export')
    .addItem('Export to CSV', 'exportDriveStructureToCSV')
    .addToUi();
}
