*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...             Saves the order HTML receipt as a PDF file.
...             Saves the screenshot of the ordered robot.
...             Embeds the screenshot of the robot to the PDF receipt.
...             Creates ZIP archive of the receipts and the images.
Library         RPA.Browser.Selenium
Library         RPA.HTTP
Library         RPA.Excel.Files
Library         RPA.PDF
Library         RPA.Robocorp.Vault
Library         RPA.Tables
Library         RPA.Archive 
Library         DateTime
Library         OperatingSystem
Library         String
Library         RPA.Dialogs

*** Variables ***
${URL} =   https://robotsparebinindustries.com/

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    WebsiteDetails
    Open Available Browser  ${secret}[url]

Get orders
    Add heading    Please provide order csv url
    Add text input   url   label=Url  rows=4
    ${result}=   Run dialog
    Download    ${result.url}    overwrite=True
    ${ordersData}=   Read table from CSV    orders.csv
    [Return]   ${ordersData}

Close the annoying modal
    Wait Until Page Contains Element    class:modal
    Click Button   Yep

Fill the form
    [Arguments]   ${order}
    Wait Until Element Is Visible    //*[@id="head"]
    Select From List By Value    //*[@id="head"]    ${order}[Head]
    Click Element    //label[./input[@id="id-body-${order}[Body]"]]
    Input Text    //form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    preview
    Click Button    //*[@id="order"]
    Wait Until Element Is Visible    //*[@id="receipt"]  

Go to order another robot
    Click Button    //*[@id="order-another"]
    Close the annoying modal
    
Store the receipt as a PDF file
    [Arguments]   ${fileName}
    Wait Until Element Is Visible    //*[@id="receipt"]
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    ${receipt_html}   ${fileName}
    [Return]   ${fileName}

Take a screenshot of the robot
    [Arguments]   ${filename}
    ${robotScreenshot}=   Screenshot    //*[@id="robot-preview-image"]   filename=${filename}
    [Return]   ${filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]   ${screenshot}   ${pdfPath}
    Add Files To Pdf   ${screenshot}   ${pdfPath}   append=True

Create a ZIP file of the receipts
    [Arguments]   ${folderName}
    Archive Folder With Zip    ${folderName}    ${folderName}.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc 
    Open the robot order website
    Close the annoying modal
    ${orders}=    Get orders
    ${currentDate}=   Get Current Date   result_format=%Y.%m.%d
    ${receiptFolder}=   Catenate   ${CURDIR}${/}output${/}   ${currentDate}
    Create Directory   ${receiptFolder}
    FOR    ${row}    IN    @{orders}
        Wait Until Keyword Succeeds    5x    5s    Fill the form   ${row}
        ${pdf}=    Store the receipt as a PDF file    ${receiptFolder}${/}${row}[Order number].pdf
        ${screenshot}=    Take a screenshot of the robot    ${CURDIR}${/}output${/}${row}[Order number].png
        ${screenshotList}=   Create List   ${screenshot}
        Embed the robot screenshot to the receipt PDF file    ${screenshotList}  ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts   ${receiptFolder}