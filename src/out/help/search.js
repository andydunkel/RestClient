var searchData = [
{
  "filename": "Getting_Started/index.html",
  "title": "Getting Started",
  "text": "Getting Started Select File \u2192 Open Folder and choose a folder for your REST project. Create or select a .rest file in the project tree. Enter a request: http GET https://postman-echo.com/get Accept: application/json Press F5 or select Request \u2192 Send. The response is displayed in the lower editor. "
},
{
  "filename": "User_Interface/index.html",
  "title": "User Interface",
  "text": "User Interface The project tree on the left displays folders and .rest files. The upper editor contains the request, and the lower editor displays the response. The menu and toolbar provide commands for opening projects, managing files, sending requests, and copying results. "
},
{
  "filename": "Project_Management/index.html",
  "title": "Project Management",
  "text": "Project Management Open a folder to use it as a REST project. Only .rest files are displayed in the project tree. Use the toolbar, menu, or context menu to create, rename, duplicate, move, and delete files or folders. Changes to the current request are saved automatically. Recently opened project folders are available under File \u2192 Recent Folders. "
},
{
  "filename": "Examples/index.html",
  "title": "Examples",
  "text": "Examples GET request http GET https://postman-echo.com/get Accept: application/json POST request \u0060\u0060\u0060http POST https://postman-echo.com/post Content-Type: application/json { \u0022message\u0022: \u0022Hello\u0022 } \u0060\u0060\u0060 Other HTTP methods such as PUT, PATCH, and DELETE use the same format. "
},
{
  "filename": "Responses/index.html",
  "title": "Responses",
  "text": "Responses The response editor displays the HTTP status, response headers, and response body. Valid JSON responses are formatted automatically. Select Request \u2192 Copy Result to copy the complete response to the clipboard. "
},
{
  "filename": "REST_Requests/index.html",
  "title": "REST Requests",
  "text": "REST Requests The first line contains the HTTP method and URL. Headers follow on separate lines. Add an empty line before the optional request body. \u0060\u0060\u0060http POST https://example.com/api/items Content-Type: application/json Authorization: Bearer TOKEN { \u0022name\u0022: \u0022Example\u0022 } \u0060\u0060\u0060 "
},
{
  "filename": "Troubleshooting/index.html",
  "title": "Troubleshooting",
  "text": "Troubleshooting Check that the first line contains an HTTP method and a complete URL. Add an empty line between the headers and request body. Check your internet connection if a request cannot be sent. Verify authorization headers and SSL certificates when access fails. If the update check does not start, make sure updater.exe is installed next to restclient.exe. "
},
{
  "filename": "Keyboard_Shortcuts/index.html",
  "title": "Keyboard Shortcuts",
  "text": "Keyboard Shortcuts Shortcut Action Ctrl\u002BO Open a project folder F5 Send the current request F9 Refresh the project tree "
},
{
  "filename": "Updates/index.html",
  "title": "Updates",
  "text": "Updates Select Help \u2192 Check for updates... to start the DA-Software Updater. The updater checks whether a newer version of DA-RestClient is available and guides you through the update. "
},
{
  "filename": "About/index.html",
  "title": "About",
  "text": "About DA-RestClient is freeware and may be used free of charge. Website: https://da-software.net/ Author: Andy Dunkel (\u0026#x61;\u0026#x6e;\u0026#x64;\u0026#x79;\u0026#x2e;\u0026#x64;\u0026#x75;\u0026#x6e;\u0026#107;e\u0026#x6c;\u0026#x40;\u0026#101;\u0026#x6b;\u0026#105;\u0026#x77;\u0026#105;\u0026#x2e;\u0026#x64;\u0026#x65;) "
},
];

function getRelativePath(relativePath) {
    var element = document.getElementById('search');
    var searchPath = element.dataset.searchpath;
    var absolutePath = searchPath + relativePath;
    return absolutePath;
}
// Get the search field and results div
var searchField = document.getElementById('search');
var resultsDiv = document.getElementById('searchResults');

// Add event listener to the search field
searchField.addEventListener('keyup', function () {
    // Get search term and make it lowercase
    var searchTerm = searchField.value.toLowerCase();

    // Split the search term into words and filter out empty strings and single characters
    var searchWords = searchTerm.split(',').filter(function (word) {
        return word.length > 2;
    });

    // Clear the results div
    resultsDiv.innerHTML = '';

    // Create a new button element
    var closeButton = document.createElement('button');
    // Change the button text to 'x'
    closeButton.innerHTML = 'x';

    // Add a class to the button for styling (optional)
    closeButton.className = 'close-button';

    // Add an event listener to the button to handle the click event
    closeButton.addEventListener('click', function () {
        // Clear the div's content when the button is clicked
        resultsDiv.innerHTML = '';
        resultsDiv.style.display = 'none';
    });

    // If the search term is empty or only whitespace, stop here
    if (!searchTerm.trim()) {
        resultsDiv.style.display = 'none';
        return;
    }

    // Filter the data
    var results = searchData.filter(file => {
        // Check if all words appear in the title or text
        return searchWords.every(word =>
            file.title.toLowerCase().includes(word) ||
            file.text.toLowerCase().includes(word)
        );
    });

    // Create an unordered list
    var resultList = document.createElement('ul');

    // Add each result to the results list
    results.forEach(result => {
        // Create a list item and a link for each result
        var resultItem = document.createElement('li');
        var resultLink = document.createElement('a');
        resultLink.textContent = result.title;
        resultLink.href = getRelativePath(result.filename);

        // Add the link to the list item
        resultItem.appendChild(resultLink);

        // Highlight all occurrences of the search terms in the text, without requiring full word matches
        var fullText = result.text;
        var snippets = [];

        // Function to find and process all occurrences of the search terms
        searchWords.forEach(word => {
            var re = new RegExp(`(\\S*\\s)?(\\S*\\s)?(\\S*\\s)?(\\S*\\s)?(\\S*\\s)?${word}(\\s\\S*)?(\\s\\S*)?(\\s\\S*)?(\\s\\S*)?(\\s\\S*)?`, 'gi');
            fullText = fullText.replace(re, function (match, ...groups) {
                var snippet = match;
                var prefix = groups.slice(0, 5).join('');
                var suffix = groups.slice(5, 10).join('');
                var matchIndex = match.toLowerCase().indexOf(word.toLowerCase());
                var startIndex = Math.max(fullText.indexOf(match) - prefix.length, 0);
                var endIndex = fullText.indexOf(match) + matchIndex + word.length + suffix.length;

                // Check if the start and end of the snippet are not the start or end of the full text
                var prefixEllipsis = startIndex > 0 ? "..." : "";
                var suffixEllipsis = endIndex < fullText.length ? "..." : "";

                snippet = prefixEllipsis + prefix + '<mark>' + match.substr(matchIndex, word.length) + '</mark>' + suffix + suffixEllipsis;

                // Avoid duplicate snippets
                if (!snippets.includes(snippet)) {
                    snippets.push(snippet);
                }

                // Return the original match with the search term highlighted, not altering the surrounding text
                return match.substr(0, matchIndex) + '<mark>' + match.substr(matchIndex, word.length) + '</mark>' + match.substr(matchIndex + word.length);
            });
        });

        // Combine all unique snippets into the highlightedText
        var highlightedText = snippets.join(' ');

        // Create a paragraph for the context and add it to the list item
        var contextParagraph = document.createElement('p');
        contextParagraph.innerHTML = highlightedText;
        resultItem.appendChild(contextParagraph);

        // Add the list item to the list
        resultList.appendChild(resultItem);
    });

    // Add the results list to the results div
    resultsDiv.appendChild(resultList);

    // Append the button to the div
    resultsDiv.appendChild(closeButton);

    // If there are no results, hide the results div and stop here
    if (results.length === 0) {
        resultsDiv.style.display = 'none';
        return;
    }

    // Show the results div
    resultsDiv.style.display = 'block';
});