# Helper functions

def autocomplete(selector, with:)
  page.driver.evaluate_script("$('#{selector}').focus().val('#{with}').keydown();")
  expect(page).to have_css('.ui-autocomplete .ui-menu-item')
  page.driver.evaluate_script("$('.ui-autocomplete .ui-menu-item').click()")
end

# Available alert methods: accept, deny, dismiss, text
def alert
  page.driver.browser.switch_to.alert
end
