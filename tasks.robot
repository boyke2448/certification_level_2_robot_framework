*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as PDF file.
...                 Saves the screenshot fo the ordered robots
...                 Enbeds the screenshot of the robot to the PDF receipt
...                 Creates ZIP archive of the receipts and images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive


*** Variables ***
${MY_OUTPUT_DIR}=       ${OUTPUT_DIR}${/}files


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Order robots
    Archive Folder With Zip    ${MY_OUTPUT_DIR}    ${OUTPUT_DIR}${/}files.zip


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Click Button    I guess so...

Order robots
    ${orders}=    Get Orders
    FOR    ${order}    IN    @{Orders}
        ${HasErrors}=    Convert To Boolean    ${True}
        WHILE    ${HasErrors}
            Wait Until Keyword Succeeds
            ...    3x
            ...    1 min
            ...    Fill from
            ...    ${order}

            ${Result}=    Does Page Contain Element    css:.alert-danger
            IF    ${Result} == ${False}
                ${HasErrors}=    Convert To Boolean    ${False}
            END
        END

        Wait Until Keyword Succeeds
        ...    3x
        ...    1 min
        ...    Save Reciept to PDF
        ...    ${order}[Order number]

        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file
        ...    ${screenshot}
        ...    ${MY_OUTPUT_DIR}${/}receipt_${order}[Order number].pdf
        Click Button    id:order-another
        Click Button    I guess so...
    END

Get Orders
    Download    https://robotsparebinindustries.com/orders.csv
    ${data}=    Read table from CSV    orders.csv
    RETURN    ${data}

Fill from
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://form/div[3]/input    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    Click Button    Order

Save Reciept to PDF
    [Arguments]    ${order_id}
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${MY_OUTPUT_DIR}${/}receipt_${order_id}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_id}
    ${screenshot}=    Screenshot    id:robot-preview-image    filename=${MY_OUTPUT_DIR}${/}image_${order_id}.png
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List
    ...    ${pdf}
    ...    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}
    Close Pdf    ${pdf}
