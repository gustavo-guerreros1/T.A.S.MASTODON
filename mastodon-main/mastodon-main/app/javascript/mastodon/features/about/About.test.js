import React from 'react';
import { render, fireEvent } from '@testing-library/react';
import { BrowserRouter as Router } from 'react-router-dom';
import About from './index';

test('el botón "Atrás" redirige a "getting-started"', () => {
  const { getByText } = render(
    <Router>
      <About />
    </Router>
  );

  const backButton = getByText('Atrás');
  fireEvent.click(backButton);


});
