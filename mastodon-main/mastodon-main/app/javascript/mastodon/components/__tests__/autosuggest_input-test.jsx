import { fromJS }  from 'immutable';

import renderer from 'react-test-renderer';

import AutosuggestInput from '../autosuggest_input';
import { countableText } from 'mastodon/features/compose/util/counter';

describe('<AutosuggestInput />', () => {
  it('show number of characters', () => {

    const account = fromJS({
        characterLength: ''
    });

    getFulltextForCharacterCounting = () => {
        return [this.state.characterLength? this.state.characterLength: '', countableText(this.state.ca)].join('');
    };

    const component = renderer.create(
        <AutosuggestInput 
            max={500} 
            text={this.getFulltextForCharacterCounting()}
        />);
    const tree      = component.toJSON()

    expect(tree).toMatchSnapshot();
  });
});
